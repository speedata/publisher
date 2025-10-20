use mlua::prelude::*;
mod aux;
mod config;
mod html;
pub mod html_to_xml;
mod imageconv;
mod logging;
mod netfetch;
mod strmod;
mod text;
mod xml;

// compile time feature flag
const IS_PRO: bool = cfg!(feature = "pro");

#[mlua::lua_module(name = "rlib")]
fn rlib(lua: &Lua) -> LuaResult<LuaTable> {
    crate::config::init_from_env();
    let root = lua.create_table()?;
    root.set("pro", IS_PRO)?;
    root.set("log", logging::lua_subtable(lua)?)?;
    root.set("xml", xml::lua_subtable(lua)?)?;
    root.set("aux", aux::lua_subtable(lua)?)?;
    root.set("str", strmod::lua_subtable(lua)?)?;
    root.set("image", imageconv::lua_subtable(lua)?)?;
    root.set("text", text::lua_subtable(lua)?)?;
    root.set("html", html::lua_subtable(lua)?)?;
    Ok(root)
}
