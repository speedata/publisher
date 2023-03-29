from os import system
from os import remove
from os import rename
from os.path import sep
from os.path import join
from os.path import isdir
from os.path import isfile
from os.path import dirname

from shutil import copy2

from re import sub

CURRENT_DIR = dirname(__file__)

MINGW = False
while not isfile(MINGW):
    MINGW = input("Input the path of mingw executable: ")

LUA_HEADERS = False
while not isdir(LUA_HEADERS):
    LUA_HEADERS = input("Input the path of lua C headers directory: ")

LUATEX = False
while not isdir(LUATEX):
    LUATEX = input("Input the path of luatex top directory: ")

copy2(
    join(dirname(dirname(CURRENT_DIR)), "go", "sphelper", "buildlib", "buildlib.go"),
    join(dirname(dirname(CURRENT_DIR)), "go", "sphelper", "buildlib", "buildlib.go_old")
)

with open(join(dirname(dirname(CURRENT_DIR)), "go", "sphelper", "buildlib", "buildlib.go"), "r", encoding="utf-8") as f:
    CONTENT = f.read()

TARGET_REGEX = 'case "windows":(.|\n)*?cmd(.|\n)*?luaglue.c(.|\n)*?}'
MINGW = MINGW.replace('\\', '\\\\')
LUA_HEADERS = LUA_HEADERS.replace('\\', '\\\\')
LUATEX = LUATEX.replace('\\', '\\\\')

LUAGLUE_C = join(dirname(dirname(CURRENT_DIR)), "c", "luaglue.c").replace('\\', '\\\\').replace(sep, '\\\\')

WIN_TARGET = rf"""case "windows":
        cmd = exec.Command(
            "{MINGW}",
            "-shared",
            "-o",
            filepath.Join(dylibbuild, "luaglue.dll"),
            "{LUAGLUE_C}",
            "-I{LUA_HEADERS}",
            "-L{LUATEX}",
            "-llua53w64",
            "-llibsplib",
            "-L"+dylibbuild)
    """ + "  }"

with open(join(dirname(dirname(CURRENT_DIR)), "go", "sphelper", "buildlib", "buildlib.go"), "w", encoding="utf-8") as f:
    f.write(sub(TARGET_REGEX, WIN_TARGET, CONTENT))

system("rake build")
system("rake buildlib")
system("rake dist")

if isfile(join(dirname(dirname(CURRENT_DIR)), "go", "sphelper", "buildlib", "buildlib.go_old")):
    remove(join(dirname(dirname(CURRENT_DIR)), "go", "sphelper", "buildlib", "buildlib.go"))
    rename(
        join(dirname(dirname(CURRENT_DIR)), "go", "sphelper", "buildlib", "buildlib.go_old"),
        join(dirname(dirname(CURRENT_DIR)), "go", "sphelper", "buildlib", "buildlib.go")
    )
