use anyhow::{anyhow, Result};

/// Non-Pro stub version of `resize_image`.
///
/// Always returns an error indicating that this feature requires the
/// Pro edition of the Speedata Publisher.
/// The signature and return type match the Pro build so that
/// the Lua bindings and higher-level code remain compatible.
pub(crate) fn resize_image(
    _filename: &str,
    _imagetype: &str,
    _width: i64,
    _height: i64,
    _resizehandler: Option<&str>,
) -> Result<String> {
    Err(anyhow!(
        "Image resizing (ResizeImage) requires the Pro version of the Speedata Publisher"
    ))
}
