#include <lauxlib.h>
#include <lualib.h>

extern int sdAddDir(lua_State* L);
extern int sdBuildFilelist(lua_State* L);
extern int sdContains(lua_State* L);
extern int sdConvertContents(lua_State* L);
extern int sdConvertImage(lua_State* L);
extern int sdConvertSVGImage(lua_State* L);
extern int sdGetErrCount(lua_State* p0);
extern int sdError(lua_State* p0);
extern int sdGetWarnCount(lua_State* p0);
extern int sdHtmlToXml(lua_State* L);
extern int sdListFonts(lua_State* L);
extern int sdLoadXMLFile(lua_State* p0);
extern int sdLoadXMLString(lua_State* p0);
extern int sdLog(lua_State* p0);
extern int sdLookupFile(lua_State* L);
extern int sdMarkdown(lua_State* p0);
extern int sdMatches(lua_State* L);
extern int sdParseHTML(lua_State* L);
extern int sdParseHTMLText(lua_State* L);
extern int sdReloadImage(lua_State* p0);
extern int sdReplace(lua_State* L);
extern int sdSegmentizeText(lua_State* p0);
extern int sdTeardown(lua_State* p0);
extern int sdTokenize(lua_State* L);


static const struct luaL_Reg myfuncs[] = {
    {"add_dir", sdAddDir},
    {"buildfilelist", sdBuildFilelist},
    {"contains", sdContains},
    {"convert_svg_image", sdConvertSVGImage},
    {"convertcontents", sdConvertContents},
    {"convertimage", sdConvertImage},
    {"errcount", sdGetErrCount},
    {"error", sdError},
    {"htmltoxml", sdHtmlToXml},
    {"listfonts", sdListFonts},
    {"load_xmlfile", sdLoadXMLFile},
    {"loadxmlstring", sdLoadXMLString},
    {"log", sdLog},
    {"lookupfile", sdLookupFile},
    {"markdown", sdMarkdown},
    {"matches", sdMatches},
    {"parse_html_text", sdParseHTMLText},
    {"parse_html", sdParseHTML},
    {"reloadimage",sdReloadImage},
    {"replace", sdReplace},
    {"segmentize_text", sdSegmentizeText},
    {"teardown", sdTeardown},
    {"tokenize", sdTokenize},
    {"warncount", sdGetWarnCount},
    {NULL, NULL},
};

int luaopen_libsplib(lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, myfuncs, 0);
  return 1;
}