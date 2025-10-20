use anyhow::{anyhow, Context, Result};
use md5;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

use image::codecs::jpeg::JpegEncoder;
use image::{imageops::FilterType, DynamicImage, ImageFormat};

pub(crate) fn resize_image(
    filename: &str,
    imagetype: &str,
    width: i64,
    height: i64,
    resizehandler: Option<&str>,
) -> Result<String> {
    // Basic parameter sanity check early for clear errors.
    if width <= 0 || height <= 0 {
        return Err(anyhow!(
            "width/height must be > 0 (got {}x{})",
            width,
            height
        ));
    }

    // Split path into parent directory and filename component.
    let src_path = Path::new(filename);
    let path_part = src_path
        .parent()
        .ok_or_else(|| anyhow!("cannot derive parent directory of input file"))?;

    // Prefix the cache key with a stable hash of the parent path
    // so files with the same name from different directories don't collide.
    let prefix = format!("{:x}", md5::compute(path_part.to_string_lossy().as_bytes()));

    let filename_part = src_path
        .file_name()
        .ok_or_else(|| anyhow!("cannot derive filename part"))?
        .to_string_lossy()
        .into_owned();

    // Resolve the cache directory:
    // - IMGCACHE overrides the default
    // - default is $TMPDIR/imagecache
    let rawimgcache = match env::var("IMGCACHE") {
        Ok(v) if !v.is_empty() => PathBuf::from(v),
        _ => env::temp_dir().join("imagecache"),
    };
    fs::create_dir_all(&rawimgcache)
        .with_context(|| format!("creating cache dir {:?}", rawimgcache))?;

    // Final destination filename encodes path-hash and target size.
    let dest_filename =
        rawimgcache.join(format!("{}_{}_{}_{}", prefix, width, height, filename_part));

    // Optional cache short-circuit: if CACHEMETHOD != "none" and file exists, reuse it.
    if env::var("CACHEMETHOD").map(|v| v != "none").unwrap_or(true) && dest_filename.exists() {
        let file_out = dest_filename.to_string_lossy().into_owned();
        crate::logging::log_with(
            "debug",
            "ResizeImage: output file already exists",
            &[("file", &file_out)],
        );
        return Ok(file_out);
    }

    // External handler path (if provided) takes precedence over built-in resizing.
    // Placeholders supported: %%input%%, %%output%%, %%width%%, %%height%%
    if let Some(handler) = resizehandler {
        if !handler.is_empty() {
            let w_s = width.to_string();
            let h_s = height.to_string();
            crate::logging::log_with(
                "debug",
                "Resize file via handler",
                &[
                    ("handler", handler),
                    ("width", &w_s),
                    ("height", &h_s),
                    ("in", filename),
                ],
            );

            // Shell-like split (quotes/escapes) via shared helper.
            let mut args = super::split_args(handler).map_err(|e| anyhow!(e))?;
            if args.is_empty() {
                return Err(anyhow!("resize handler is empty after parsing"));
            }

            // Expand placeholders in-place.
            let dest = dest_filename.to_string_lossy().into_owned();
            for a in &mut args {
                *a = a
                    .replace("%%input%%", filename)
                    .replace("%%output%%", &dest)
                    .replace("%%width%%", &w_s)
                    .replace("%%height%%", &h_s);
            }

            // First token is the executable; the rest are argv.
            let exe = args.remove(0);
            let cmd_s = format!("{args:?} with exe {exe}");
            crate::logging::log_with("debug", "Command for image resizing", &[("cmd", &cmd_s)]);

            // Run external tool and surface useful context if it fails to spawn.
            let status = Command::new(&exe)
                .args(&args)
                .status()
                .with_context(|| format!("failed to spawn resize handler '{}'", exe))?;
            if !status.success() {
                return Err(anyhow!(
                    "resize handler exited with status {}",
                    status.code().unwrap_or(-1)
                ));
            }

            // Ensure the handler actually produced the file we expect.
            if dest_filename.exists() {
                return Ok(dest);
            }
            crate::logging::log_with(
                "error",
                "Error running resize handler: output file not created",
                &[("handler", handler), ("out", &dest)],
            );
            return Err(anyhow!("Resize handler did not create output file"));
        }
    }

    // If no handler was provided (or it failed), fall back to the built-in resizer.
    if dest_filename.exists() {
        return Ok(dest_filename.to_string_lossy().into_owned());
    }

    let out_s = dest_filename.to_string_lossy().into_owned();
    crate::logging::log_with("info", "Resize file", &[("out", &out_s)]);

    // Load source image and resize using a bilinear filter (Triangle).
    let img = image::open(src_path).with_context(|| format!("opening image '{}'", filename))?;
    let resized = resize_bilinear(&img, width as u32, height as u32);

    // Encode output in requested format (PNG or JPEG).
    match imagetype {
        "png" => {
            let mut f = fs::File::create(&dest_filename)
                .with_context(|| format!("create {:?}", dest_filename))?;
            resized
                .write_to(&mut f, ImageFormat::Png)
                .context("write PNG output")?;
        }
        "jpg" | "jpeg" => {
            let mut f = fs::File::create(&dest_filename)
                .with_context(|| format!("create {:?}", dest_filename))?;
            // Reasonable default quality; adjust via handler path if you need other qualities.
            let mut encoder = JpegEncoder::new_with_quality(&mut f, 70);
            encoder
                .encode_image(&resized)
                .context("write JPEG output")?;
        }
        _ => {
            return Err(anyhow!(
                "Image file type not supported (resize image): {}",
                imagetype
            ))
        }
    }

    Ok(dest_filename.to_string_lossy().into_owned())
}

// Small wrapper that makes the chosen filter explicit and keeps the callsite clean.
fn resize_bilinear(img: &DynamicImage, w: u32, h: u32) -> DynamicImage {
    DynamicImage::ImageRgba8(image::imageops::resize(img, w, h, FilterType::Triangle))
}
