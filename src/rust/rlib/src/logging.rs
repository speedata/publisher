use chrono::Local;
use mlua::prelude::*;
use mlua::Variadic;
use std::sync::OnceLock;
use std::{
    env,
    fs::{File, OpenOptions},
    io::{BufWriter, Write},
    sync::{Arc, Mutex},
};

/// Global, lazily-initialized logger. Access is synchronized via `Mutex`.
/// We keep it behind `Arc` so Lua/Rust call sites can share it safely.
static LOGGER: OnceLock<Arc<Mutex<Logger>>> = OnceLock::new();

/// Map string log levels to a comparable rank (lower = more important).
/// This feeds a simple threshold filter; unknown levels default to `info`.
fn level_rank(s: &str) -> u8 {
    match s {
        "error" => 0,
        "warn" => 1,
        "message" | "info" => 2,
        "debug" => 3,
        "trace" => 4,
        _ => 2, // unrecognized -> treat as "info"
    }
}

/// Minimal XML escaper for attribute values and text nodes.
/// Keeps output valid for the `<entry ...>` lines we produce.
fn xml_escape(input: &str) -> String {
    let mut out = String::with_capacity(input.len());
    for c in input.chars() {
        match c {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '"' => out.push_str("&quot;"),
            '\'' => out.push_str("&apos;"),
            _ => out.push(c),
        }
    }
    out
}

/// Logger writes a single XML file:
/// - `<log ...>` header with level/version/time
/// - many `<entry ...>` lines
/// - `<summary ...>` and `</log>` at the end (also on Drop)
struct Logger {
    writer: BufWriter<File>,
    errors: usize,
    warnings: usize,
    closed: bool,
    /// configured (string) level, e.g. "info"
    level: String,
    /// numeric threshold derived from `level`
    threshold: u8,
    /// if true, echo a human-readable line to stdout for each entry
    verbose: bool,
}

impl Logger {
    /// Create/overwrite the log file and emit the opening `<log ...>` tag.
    /// Uses env `PUBLISHERVERSION` and compile-time `cfg(feature="pro")`.
    fn new(path: &str, level: &str, verbose: bool) -> std::io::Result<Self> {
        let version = env::var("PUBLISHERVERSION").unwrap_or_else(|_| "dev".to_string());
        let pro = cfg!(feature = "pro");

        let file = OpenOptions::new()
            .create(true)
            .truncate(true)
            .write(true)
            .open(path)?;
        let mut writer = BufWriter::new(file);

        // Reference-friendly, compact timestamp like "Oct 20 13:42:05"
        let t = Local::now().format("%b %d %H:%M:%S").to_string();

        // Opening root element holds global metadata
        writeln!(
            writer,
            r#"<log loglevel="{level}" time="{t}" version="{version}" pro="{pro}">"#,
            level = level,
            t = t,
            version = version,
            pro = if pro { "yes" } else { "no" }
        )?;
        writer.flush()?;

        Ok(Self {
            writer,
            errors: 0,
            warnings: 0,
            closed: false,
            level: level.to_string(),
            threshold: level_rank(level),
            verbose,
        })
    }

    /// Core: write one `<entry ...>` line if `level` passes the threshold.
    /// Also increments error/warn counters and mirrors to stdout if `verbose`.
    fn write(&mut self, level: &str, msg: &str, attrs: &[(String, String)]) {
        if self.closed {
            return; // nothing after close
        }
        if level_rank(level) > self.threshold {
            return; // filtered out
        }

        // Maintain counters for later summary
        match level {
            "error" => self.errors += 1,
            "warn" => self.warnings += 1,
            _ => {}
        }

        // Build `<entry level="..." msg="...">` with sorted/escaped attributes
        let mut line = String::with_capacity(64 + msg.len() + attrs.len() * 16);
        line.push_str(r#"  <entry"#);
        line.push_str(&format!(r#" level="{}" msg=""#, xml_escape(level)));
        line.push_str(&xml_escape(msg));
        line.push('"');

        // Append key/value attributes in call order (already owned Strings)
        for (k, v) in attrs {
            line.push_str(" ");
            line.push_str(&xml_escape(k));
            line.push_str(r#"=""#);
            line.push_str(&xml_escape(v));
            line.push('"');
        }
        line.push_str("/>\n");

        // Best-effort write to disk; don't abort on I/O errors, but warn on stderr.
        if let Err(e) = self.writer.write_all(line.as_bytes()) {
            eprintln!("log write error: {e}");
        }

        // Optional echo for human eyes, with short, level-based prefix.
        if self.verbose {
            let prefix = match level {
                "error" => "E:  ",
                "warn" => "W:  ",
                "message" | "info" => "·   ",
                "debug" => "D:  ",
                "trace" => "T:  ",
                _ => "·   ",
            };
            if attrs.is_empty() {
                println!("{prefix}{msg}");
            } else {
                let kv = attrs
                    .iter()
                    .map(|(k, v)| format!("{k}={v}"))
                    .collect::<Vec<_>>()
                    .join(",");
                println!("{prefix}{msg} ({kv})");
            }
        }
    }

    /// Finalize the file with `<summary ...>` and `</log>`. Idempotent.
    fn close(&mut self) {
        if self.closed {
            return;
        }
        let _ = writeln!(
            self.writer,
            r#"  <summary errors="{}" warnings="{}"></summary>"#,
            self.errors, self.warnings
        );
        let _ = writeln!(self.writer, "</log>");
        let _ = self.writer.flush();
        self.closed = true;
    }
}

impl Drop for Logger {
    /// Ensure the file always closes cleanly, even if the process exits abruptly.
    fn drop(&mut self) {
        self.close();
    }
}

/// Ensure the global logger exists exactly once, using the given config.
fn ensure_init(path: &str, level: &str, verbose: bool) -> LuaResult<()> {
    if LOGGER.get().is_none() {
        let lg = Logger::new(path, level, verbose).map_err(LuaError::external)?;
        LOGGER.set(Arc::new(Mutex::new(lg))).ok();
    }
    Ok(())
}

/// Current error count (0 if logger not initialized).
pub fn error_count() -> usize {
    LOGGER
        .get()
        .and_then(|arc| arc.lock().ok().map(|lg| lg.errors))
        .unwrap_or(0)
}

/// Current warning count (0 if logger not initialized).
pub fn warn_count() -> usize {
    LOGGER
        .get()
        .and_then(|arc| arc.lock().ok().map(|lg| lg.warnings))
        .unwrap_or(0)
}

/// Convert a Lua value into an attribute string (primitives only).
/// Tables/functions/etc. are ignored to avoid noisy logs.
fn val_to_attr_string(v: &LuaValue) -> LuaResult<Option<String>> {
    Ok(match v {
        LuaValue::Nil => None,
        LuaValue::Boolean(b) => Some(if *b { "true".into() } else { "false".into() }),
        LuaValue::Integer(i) => Some(i.to_string()),
        LuaValue::Number(n) => Some({
            // Nice formatting: "3" instead of "3.0"
            if n.fract() == 0.0 {
                format!("{:.0}", n)
            } else {
                n.to_string()
            }
        }),
        LuaValue::String(s) => Some(s.to_str()?.to_string()),
        _ => None, // ignore tables, functions, userdata, threads, lightuserdata
    })
}

/// Expose the logger as a Lua subtable `rlib.log`.
/// Functions:
///   - init{ path, level="info", verbose=false }
///   - close(), flush()
///   - set_verbose(bool), set_level("warn"/"info"/"debug"/...)
///   - errcount() → int, warncount() → int
///   - log(level, message, [key, value, ...])
pub fn lua_subtable(lua: &Lua) -> LuaResult<LuaTable> {
    let t = lua.create_table()?;

    // rlib.log.init{ path="publisher-log.xml", level="info", verbose=false }
    t.set(
        "init",
        lua.create_function(|_, cfg: LuaTable| {
            let path: String = cfg.get("path")?;
            let level: String = cfg
                .get::<Option<String>>("level")?
                .unwrap_or_else(|| "info".into());
            let verbose: bool = cfg.get::<Option<bool>>("verbose")?.unwrap_or(false);
            ensure_init(&path, &level, verbose)
        })?,
    )?;

    // rlib.log.close()
    t.set(
        "close",
        lua.create_function(|_, ()| {
            if let Some(arc) = LOGGER.get() {
                if let Ok(mut lg) = arc.lock() {
                    lg.close();
                }
            }
            Ok(())
        })?,
    )?;

    // rlib.log.flush()
    t.set(
        "flush",
        lua.create_function(|_, ()| {
            if let Some(arc) = LOGGER.get() {
                if let Ok(mut lg) = arc.lock() {
                    let _ = lg.writer.flush();
                }
            }
            Ok(())
        })?,
    )?;

    // rlib.log.set_verbose(true|false)
    t.set(
        "set_verbose",
        lua.create_function(|_, v: bool| {
            if let Some(arc) = LOGGER.get() {
                if let Ok(mut lg) = arc.lock() {
                    lg.verbose = v;
                }
            }
            Ok(())
        })?,
    )?;

    // rlib.log.set_level("warn" | "info" | "debug" | ...)
    t.set(
        "set_level",
        lua.create_function(|_, lvl: String| {
            if let Some(arc) = LOGGER.get() {
                if let Ok(mut lg) = arc.lock() {
                    lg.level = lvl.clone();
                    lg.threshold = level_rank(&lvl);
                }
            }
            Ok(())
        })?,
    )?;

    // rlib.log.errcount() → integer
    t.set("errcount", lua.create_function(|_, ()| Ok(error_count()))?)?;

    // rlib.log.warncount() → integer
    t.set("warncount", lua.create_function(|_, ()| Ok(warn_count()))?)?;

    // rlib.log.log(level, message, key, value, key, value, ...)
    // Extra args are read as pairs; dangling value is ignored (optional warning in verbose mode).
    t.set(
        "log",
        lua.create_function(|_, args: Variadic<LuaValue>| {
            if args.len() < 2 {
                return Err(LuaError::external(
                    "rlib.log.log(level, message, [key, value, ...]): need at least 2 arguments",
                ));
            }

            // Level as String
            let level: String = match &args[0] {
                LuaValue::String(s) => s.to_str()?.to_owned(),
                v => {
                    return Err(LuaError::external(format!(
                        "rlib.log.log: level must be string, got {v:?}"
                    )))
                }
            };

            // Message as String
            let msg: String = match &args[1] {
                LuaValue::String(s) => s.to_str()?.to_owned(),
                v => {
                    return Err(LuaError::external(format!(
                        "rlib.log.log: message must be string, got {v:?}"
                    )))
                }
            };

            // Collect key/value attributes in call order
            let mut attrs_vec: Vec<(String, String)> = Vec::new();
            if args.len() > 2 {
                let extra = &args[2..];
                let mut i = 0usize;
                while i + 1 < extra.len() {
                    let k = &extra[i];
                    let v = &extra[i + 1];

                    if let LuaValue::String(ks) = k {
                        if let Some(val) = val_to_attr_string(v)? {
                            attrs_vec.push((ks.to_str()?.to_owned(), val));
                        }
                    }
                    i += 2;
                }
                // One dangling value? Ignore it silently unless verbose is on.
                if extra.len() % 2 == 1 {
                    if let Some(arc) = LOGGER.get() {
                        if let Ok(lg) = arc.lock() {
                            if lg.verbose {
                                println!("W:  rlib.log.log: ignoring dangling key/value argument");
                            }
                        }
                    }
                }
            }

            if let Some(arc) = LOGGER.get() {
                if let Ok(mut lg) = arc.lock() {
                    lg.write(&level, &msg, &attrs_vec);
                }
            }
            Ok(())
        })?,
    )?;

    Ok(t)
}

/// Convenience: log without attributes (no-op if logger not initialized).
pub fn log_simple(level: &str, msg: &str) {
    log_with(level, msg, &[]);
}

/// Convenience: log with attributes (no-op if logger not initialized).
pub fn log_with(level: &str, msg: &str, attrs: &[(&str, &str)]) {
    if let Some(arc) = LOGGER.get() {
        if let Ok(mut lg) = arc.lock() {
            // Convert to owned Strings once for the write call
            let owned: Vec<(String, String)> = attrs
                .iter()
                .map(|(k, v)| (k.to_string(), v.to_string()))
                .collect();
            lg.write(level, msg, &owned);
        }
    }
}
