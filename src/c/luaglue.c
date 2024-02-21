#include "luaglue.h"

#include <lauxlib.h>
#include <lua.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void stackDump(lua_State *L) {
  int i;
  int top = lua_gettop(L);
  for (i = 1; i <= top; i++) { /* repeat for each level */
    int t = lua_type(L, i);
    printf("%d: ",i);
    switch (t) {
      case LUA_TSTRING: /* strings */
        printf("`%s'", lua_tostring(L, i));
        break;

      case LUA_TBOOLEAN: /* booleans */
        printf(lua_toboolean(L, i) ? "true" : "false");
        break;

      case LUA_TNUMBER: /* numbers */
        printf("%g", lua_tonumber(L, i));
        break;

      default: /* other values */
        printf("%s", lua_typename(L, t));
        break;
    }
    printf("\n"); /* put a separator */
  }
  printf("\n"); /* end the listing */
}


int handleerror(lua_State *L, const char *retvalue) {
  const char *errorpattern = "^%*%*err";
  lua_getglobal(L, "string");
  lua_getfield(L, -1, "match");
  lua_pushstring(L, retvalue);
  lua_pushstring(L, errorpattern);
  int err = lua_pcall(L, 2, 1, 0);

  if (lua_isnil(L, -1) == 1) {
    return 0;
  }

  lua_getglobal(L, "string");
  lua_getfield(L, -1, "gsub");
  lua_pushstring(L, retvalue);
  lua_pushstring(L, errorpattern);
  lua_pushstring(L, "");
  lua_pcall(L, 3, 1, 0);

  const char *errmsg = luaL_checkstring(L, -1);

  lua_getglobal(L, "err");
  lua_insert(L, -2);
  lua_pcall(L, 1, 0, 0);
  return 1;
}

static int lua_adddir(lua_State *L) {
  const char *pathname = luaL_checkstring(L, 1);
  sdAddDir(pathname);
  return 0;
}

static int lua_buildfilelist(lua_State *L) {
  sdBuildFilelist();
  return 0;
}

static int lua_contains(lua_State *L) {
  const char *haystack = luaL_checkstring(L, 1);
  const char *needle = luaL_checkstring(L, 2);
  const char *ret = sdContains(haystack, needle);
  lua_pushstring(L, ret);
  return 1;
}

static int lua_matches(lua_State *L) {
  const char *text = luaL_checkstring(L, 1);
  const char *regexp = luaL_checkstring(L, 2);
  const int ret = sdMatches(text, regexp);
  lua_pushboolean(L, ret);
  return 1;
}

static int lua_convertimage(lua_State *L) {
  const char *filename = luaL_checkstring(L, 1);
  const char *imagehandler = luaL_checkstring(L, 2);
  lua_pop(L, 1);
  lua_pop(L, 1);

  char *ret = sdConvertImage(filename, imagehandler);
  if (handleerror(L, ret) == 1) {
    return 0;
  }
  if (strncmp(ret, "", 1) == 0) {
    return 0;
  }
  lua_pushstring(L, ret);

  return 1;
}

static int lua_convertsvgimage(lua_State *L) {
  const char *filename = luaL_checkstring(L, 1);
  const char *ret = sdConvertSVGImage(filename);
  lua_pop(L, 1);

  if (handleerror(L, ret) == 1) {
    return 0;
  }
  if (strncmp(ret, "", 1) == 0) {
    return 0;
  }
  lua_pushstring(L, ret);

  return 1;
}

static int lua_convertcontents(lua_State *L) {
  const char *contents = luaL_checkstring(L, 1);
  const char *imagehandler = luaL_checkstring(L, 2);
  lua_pop(L, 1);
  lua_pop(L, 1);
  const char *ret = sdContains(contents, imagehandler);
  if (handleerror(L, ret) == 1) {
    return 0;
  }
  if (strncmp(ret, "", 1) == 0) {
    return 0;
  }
  lua_pushstring(L, ret);

  return 1;
}

static int lua_parsehtmltext(lua_State *L) {
  const char *htmltext = luaL_checkstring(L, 1);
  const char *csstext = luaL_checkstring(L, 2);
  lua_pop(L, 1);
  lua_pop(L, 1);
  luaL_Buffer b;
  luaL_buffinit(L, &b);
  luaL_addstring(&b, "<body>");
  luaL_addstring(&b, htmltext);
  luaL_addstring(&b, "</body>");
  luaL_pushresult(&b);
  htmltext = luaL_checkstring(L, -1);
  const char *csshtmltree = sdParseHTMLText(htmltext, csstext);
  lua_pushstring(L, csshtmltree);
  return 1;
}

static int lua_parsehtml(lua_State *L) {
  const char *filename = luaL_checkstring(L, 1);
  lua_pop(L, 1);
  const char *ret = sdParseHTML(filename);
  lua_pushstring(L, ret);
  return 1;
}

static int lua_htmltoxml(lua_State *L) {
  const char *input = luaL_checkstring(L, 1);
  lua_pop(L, 1);
  const char *ret = sdHtmlToXml(input);
  lua_pushstring(L, ret);
  return 1;
}

static int lua_listfonts(lua_State *L) {
  char **ret = sdListFonts();
  lua_newtable(L);
  int i = 0;
  for (char *c = *ret; c; c = *++ret) {
    i++;
    lua_pushstring(L, c);
    lua_rawseti(L, -2, i);
  }
  return 1;
}

static int lua_lookupfile(lua_State *L) {
  const char *filename = luaL_checkstring(L, -1);
  lua_pop(L, 1);
  const char *ret = sdLookupFile(filename);

  if (handleerror(L, ret) == 1) {
    return 0;
  }

  lua_pushstring(L, ret);
  return 1;
}

static int lua_sdreplace(lua_State *L) {
  const char *text = luaL_checkstring(L, 1);
  const char *rexpr = luaL_checkstring(L, 2);
  const char *repl = luaL_checkstring(L, 3);
  const char *ret = sdReplace(text, rexpr, repl);
  lua_pushstring(L, ret);
  return 1;
}

static int lua_segmentize(lua_State *L) {
  const char *inputstring = luaL_checkstring(L, 1);
  lua_pop(L, 1);
  struct splitvalues *sv = sdSegmentize(inputstring);
  lua_newtable(L);
  int j = 0;
  for (int i = 0; i < sv->count; i++) {
    j++;
    lua_newtable(L);
    lua_pushinteger(L, sv->directions[i]);
    lua_rawseti(L, -2, 1);
    lua_pushstring(L, sv->splitted[i]);
    lua_rawseti(L, -2, 2);
    lua_rawseti(L, -2, j);
  }

  return 1;
}

static int lua_tokenize(lua_State *L) {
  const char *text = luaL_checkstring(L, 1);
  const char *rexpr = luaL_checkstring(L, 2);
  lua_pop(L, 1);
  lua_pop(L, 1);
  char **ret = sdTokenize(text, rexpr);
  lua_newtable(L);
  int i = 0;
  for (char *c = *ret; c; c = *++ret) {
    i++;
    lua_pushstring(L, c);
    lua_rawseti(L, -2, i);
  }
  return 1;
}

static int lua_teardown(lua_State *L) {
  sdTeardown();
  return 0;
}

static int lua_errcount(lua_State *L) {
  int a = sdGetErrCount();
  lua_pushinteger(L, a);
  return 1;
}

static int lua_warncount(lua_State *L) {
  int a = sdGetWarnCount();
  lua_pushinteger(L, a);
  return 1;
}

static const struct luaL_Reg myfuncs[] = {
    {"add_dir", lua_adddir},
    {"buildfilelist", lua_buildfilelist},
    {"contains", lua_contains},
    {"convertcontents", lua_convertcontents},
    {"convertimage", lua_convertimage},
    {"convert_svg_image", lua_convertsvgimage},
    {"htmltoxml", lua_htmltoxml},
    {"listfonts", lua_listfonts},
    {"loadxmlstring", sdLoadXMLString},
    {"load_xmlfile", sdLoadXMLFile},
    {"lookupfile", lua_lookupfile},
    {"matches", lua_matches},
    {"parse_html_text", lua_parsehtmltext},
    {"parse_html", lua_parsehtml},
    {"reloadimage",sdReloadImage},
    {"replace", lua_sdreplace},
    {"segmentize", lua_segmentize},
    {"tokenize", lua_tokenize},
    {"log", sdLog},
    {"errcount", lua_errcount},
    {"warncount", lua_warncount},
    {"teardown", lua_teardown},
    {NULL, NULL},
};

int luaopen_luaglue(lua_State *L) {
  lua_newtable(L);
  luaL_setfuncs(L, myfuncs, 0);
  return 1;
}