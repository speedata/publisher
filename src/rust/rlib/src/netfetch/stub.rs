use anyhow::{anyhow, Result};

/// Non-Pro stub: always error (matches your Go: return "", error)
pub(crate) fn save_file_from_url(_raw_url: &str) -> Result<String> {
    Err(anyhow!(
        "Downloading from the internet needs speedata Publisher Pro"
    ))
}
