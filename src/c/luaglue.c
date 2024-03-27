#include "luaglue.h"

#include <lauxlib.h>

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


int luaopen_luaglue(lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, myfuncs, 0);
  return 1;
}

