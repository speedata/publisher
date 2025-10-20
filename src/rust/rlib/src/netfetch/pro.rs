#![cfg(feature = "pro")]

use anyhow::{anyhow, bail, Result};
use reqwest::blocking::Client;
use reqwest::StatusCode;
use std::{
    env, fs,
    io::{self, Write},
    path::{Path, PathBuf},
};
use url::Url;

/// Public entry point:
/// Downloads an HTTP/HTTPS resource to the image cache directory,
/// with simple caching controlled by `CACHEMETHOD` ("none" or "optimal").
///
/// Returns:
/// - Ok("<path/to/local/file>") on success
/// - Ok("") if the remote returned 404 (matches your Go code's "empty string")
/// - Err(_) for other errors (e.g., unsupported scheme, I/O errors, etc.)
pub(crate) fn save_file_from_url(raw_url: &str) -> Result<String> {
    let parsed = Url::parse(raw_url)?;
    if parsed.scheme() != "http" && parsed.scheme() != "https" {
        bail!("unsupported scheme: {}", parsed.scheme());
    }

    // Resolve cache directory from IMGCACHE (fallback: $TMPDIR/imagecache)
    let imgcache = resolve_cache_dir()?;
    ensure_cache_dir(&imgcache)?;

    // Build deterministic paths (data + sidecar meta)
    let (data_path, meta_path) = build_cache_paths(&imgcache, &parsed, raw_url);

    // Choose caching strategy
    let cachemethod = env::var("CACHEMETHOD").unwrap_or_else(|_| "none".to_string());

    // "optimal" tries conditional validation (HEAD + If-None-Match / If-Modified-Since).
    if cachemethod.eq_ignore_ascii_case("optimal") {
        if let Some(local) = try_validate_or_refresh(&parsed, &data_path, &meta_path)? {
            return Ok(local);
        }
        // Otherwise fall through to fresh download.
    }

    // If CACHEMETHOD != "none" and a file already exists, reuse it (cheap hit).
    if !cachemethod.eq_ignore_ascii_case("none") && data_path.exists() {
        return Ok(path_to_string(&data_path));
    }

    // Fresh download (always for "none", otherwise only when we didn't early-return above).
    download_fresh(&parsed, &data_path, Some(&meta_path)).map(|()| path_to_string(&data_path))
}

/// Resolve the image cache directory from environment or default.
fn resolve_cache_dir() -> io::Result<PathBuf> {
    match env::var_os("IMGCACHE") {
        Some(v) if !v.is_empty() => Ok(PathBuf::from(v)),
        _ => {
            let mut p = std::env::temp_dir();
            p.push("imagecache");
            Ok(p)
        }
    }
}

/// Ensure the directory exists and is a directory.
fn ensure_cache_dir(dir: &Path) -> io::Result<()> {
    match fs::metadata(dir) {
        Ok(md) if md.is_dir() => Ok(()),
        Ok(_) => Err(io::Error::new(
            io::ErrorKind::Other,
            "IMGCACHE exists but is not a directory",
        )),
        Err(e) if e.kind() == io::ErrorKind::NotFound => fs::create_dir_all(dir),
        Err(e) => Err(e),
    }
}

/// Build the local filename and sidecar metadata filename.
/// We use md5(url) for a stable key, and try to preserve the remote extension.
fn build_cache_paths(cache_dir: &Path, parsed: &Url, raw_url: &str) -> (PathBuf, PathBuf) {
    let hex = format!("{:x}", ::md5::compute(raw_url.as_bytes()));

    // Try to preserve an extension from the last path segment
    let ext = parsed
        .path_segments()
        .and_then(|it| it.last())
        .and_then(|leaf| Path::new(leaf).extension())
        .and_then(|e| e.to_str())
        .unwrap_or("");

    let fname = if ext.is_empty() {
        hex.clone()
    } else {
        format!("{}.{}", hex, ext)
    };
    let data = cache_dir.join(fname);
    let meta = cache_dir.join(format!("{}.meta", hex)); // metadata keyed only by the md5 hex

    (data, meta)
}

/// Try to validate the local cache via HEAD + If-* and refresh when stale.
/// Returns:
/// - Some(local_path) if the local file is valid or was refreshed
/// - None if validation couldn't conclude (caller should fresh-download)
fn try_validate_or_refresh(url: &Url, local: &Path, meta: &Path) -> Result<Option<String>> {
    let client = Client::builder()
        .user_agent("speedata-publisher/rlib (cache=optimal)")
        .build()?;

    // Load previous ETag / Last-Modified from sidecar
    let (etag, last_mod) = load_meta(meta);

    let mut req = client.head(url.clone());
    if let Some(ref e) = etag {
        req = req.header(reqwest::header::IF_NONE_MATCH, e.as_str());
    }
    if let Some(ref lm) = last_mod {
        req = req.header(reqwest::header::IF_MODIFIED_SINCE, lm.as_str());
    }

    // If HEAD fails (server doesn’t support it, or network hiccup):
    // - If we already have a local file, trust it (cheap success)
    // - Otherwise ask caller to do a fresh GET
    let resp = match req.send() {
        Ok(r) => r,
        Err(_) => {
            if local.exists() {
                return Ok(Some(path_to_string(local)));
            } else {
                return Ok(None);
            }
        }
    };

    match resp.status() {
        StatusCode::NOT_MODIFIED => {
            // 304: local file is still valid
            if local.exists() {
                Ok(Some(path_to_string(local)))
            } else {
                // 304 without local file — weird, ask caller to download fresh
                Ok(None)
            }
        }
        StatusCode::OK => {
            // Server acknowledges the resource — refresh with a GET
            download_with_client(&client, url, local, Some(meta))?;
            Ok(Some(path_to_string(local)))
        }
        StatusCode::NOT_FOUND => {
            // Mirror your Go behavior: remote missing => return empty string
            if local.exists() {
                let _ = fs::remove_file(local);
            }
            Ok(Some(String::new()))
        }
        _ => {
            // Ambiguous status. Reuse local if we have it; otherwise caller will fresh-download.
            if local.exists() {
                Ok(Some(path_to_string(local)))
            } else {
                Ok(None)
            }
        }
    }
}

/// Always download a fresh copy to a temp file and atomically rename.
/// Optionally writes a sidecar `.meta` with ETag/Last-Modified.
fn download_fresh(url: &Url, dest: &Path, meta_out: Option<&Path>) -> Result<()> {
    let client = Client::builder()
        .user_agent("speedata-publisher/rlib")
        .build()?;
    download_with_client(&client, url, dest, meta_out)
}

/// GET download; writes content to `dest`. If `meta_out` is provided, writes ETag/Last-Modified.
fn download_with_client(
    client: &Client,
    url: &Url,
    dest: &Path,
    meta_out: Option<&Path>,
) -> Result<()> {
    // Response muss mut sein, wenn wir ihn streamen
    let mut resp = client.get(url.clone()).send()?;
    if resp.status() == StatusCode::NOT_FOUND {
        return Err(anyhow!("resource not found (404)"));
    }
    resp.error_for_status_ref()?; // prüft Status ohne zu konsumieren

    if let Some(parent) = dest.parent() {
        fs::create_dir_all(parent)?;
    }

    // Header abgreifen, bevor wir den Body konsumieren
    let etag = resp
        .headers()
        .get(reqwest::header::ETAG)
        .and_then(|v| v.to_str().ok())
        .map(|s| s.to_string());
    let lastmod = resp
        .headers()
        .get(reqwest::header::LAST_MODIFIED)
        .and_then(|v| v.to_str().ok())
        .map(|s| s.to_string());

    // Body direkt in die Datei streamen (ohne bytes())
    let mut f = fs::File::create(dest)?;
    io::copy(&mut resp, &mut f)?; // <— verbraucht den Body, aber wir brauchen resp danach nicht mehr
    f.flush()?;

    // Sidecar schreiben (best effort)
    if let Some(meta_path) = meta_out {
        let mut meta = fs::File::create(meta_path)?;
        writeln!(meta, "ETag: {}", etag.as_deref().unwrap_or(""))?;
        writeln!(meta, "Last-Modified: {}", lastmod.as_deref().unwrap_or(""))?;
    }

    Ok(())
}

/// Read ETag / Last-Modified from a sidecar `.meta` file.
fn load_meta(meta: &Path) -> (Option<String>, Option<String>) {
    match fs::read_to_string(meta) {
        Ok(s) => {
            let mut etag = None;
            let mut last_mod = None;
            for line in s.lines() {
                if let Some(v) = line.strip_prefix("ETag:") {
                    etag = Some(v.trim().to_string());
                } else if let Some(v) = line.strip_prefix("Last-Modified:") {
                    last_mod = Some(v.trim().to_string());
                }
            }
            (etag, last_mod)
        }
        Err(_) => (None, None),
    }
}

fn path_to_string(p: &Path) -> String {
    p.to_string_lossy().into_owned()
}
