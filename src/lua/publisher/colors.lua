--
--  colors.lua
--  speedata publisher
--
--  Color definitions and helpers.
--

file_start("publisher/colors.lua")

---@class colors_module
local M = {}

---@alias ColorModel "rgb"|"cmyk"|"gray"|"spotcolor"

---@class Color
---@field model ColorModel
---@field pdfstring string Combined PDF color command (fill + stroke).
---@field index integer Position in `colortable`.
---@field r? string|number Red channel (rgb).
---@field g? string|number Green channel (rgb) or gray value (gray).
---@field b? string|number Blue channel (rgb).
---@field c? string|number Cyan (cmyk).
---@field m? string|number Magenta (cmyk).
---@field y? string|number Yellow (cmyk).
---@field k? string|number Black (cmyk).
---@field saturation? number Spot color saturation in [0,1].
---@field colornum? integer Spot color object number.
---@field overprint? boolean Whether overprint is enabled (spot colors).
---@field pdfstring_fill? string Lazily computed fill-only command (via metatable).
---@field pdfstring_stroking? string Lazily computed stroke-only command (via metatable).

-- The spot colors used in the document (even when discarded)
---@type table<integer, true>
M.used_spotcolors = {}

-- The predefined colors. index = 1 because we "know" that black will be the first registered color.
---@type table<string, Color>
M.colors  = {
  black = { model="gray", g = "0", pdfstring = " 0 G 0 g ", index = 1 },
  aliceblue = { model="rgb", r="0.941" , g="0.973" , b="1" , pdfstring = "0.941 0.973 1 rg 0.941 0.973 1 RG", index = 2},
  orange = { model="rgb", r="1" , g="0.647" , b="0" , pdfstring = "1 0.647 0 rg 1 0.647 0 RG", index = 3},
  rebeccapurple = { model="rgb", r="0.4" , g="0.2" , b="0.6" , pdfstring = "0.4 0.2 0.6 rg 0.4 0.2 0.6 RG", index = 4},
  antiquewhite = { model="rgb", r="0.98" , g="0.922" , b="0.843" , pdfstring = "0.98 0.922 0.843 rg 0.98 0.922 0.843 RG", index = 5},
  aqua = { model="rgb", r="0" , g="1" , b="1" , pdfstring = "0 1 1 rg 0 1 1 RG", index = 6},
  aquamarine = { model="rgb", r="0.498" , g="1" , b="0.831" , pdfstring = "0.498 1 0.831 rg 0.498 1 0.831 RG", index = 7},
  azure = { model="rgb", r="0.941" , g="1" , b="1" , pdfstring = "0.941 1 1 rg 0.941 1 1 RG", index = 8},
  beige = { model="rgb", r="0.961" , g="0.961" , b="0.863" , pdfstring = "0.961 0.961 0.863 rg 0.961 0.961 0.863 RG", index = 9},
  bisque = { model="rgb", r="1" , g="0.894" , b="0.769" , pdfstring = "1 0.894 0.769 rg 1 0.894 0.769 RG", index = 10},
  blanchedalmond = { model="rgb", r="1" , g="0.894" , b="0.769" , pdfstring = "1 0.894 0.769 rg 1 0.894 0.769 RG", index = 11},
  blue = { model="rgb", r="0" , g="0" , b="1" , pdfstring = "0 0 1 rg 0 0 1 RG", index = 12},
  blueviolet = { model="rgb", r="0.541" , g="0.169" , b="0.886" , pdfstring = "0.541 0.169 0.886 rg 0.541 0.169 0.886 RG", index = 13},
  brown = { model="rgb", r="0.647" , g="0.165" , b="0.165" , pdfstring = "0.647 0.165 0.165 rg 0.647 0.165 0.165 RG", index = 14},
  burlywood = { model="rgb", r="0.871" , g="0.722" , b="0.529" , pdfstring = "0.871 0.722 0.529 rg 0.871 0.722 0.529 RG", index = 15},
  cadetblue = { model="rgb", r="0.373" , g="0.62" , b="0.627" , pdfstring = "0.373 0.62 0.627 rg 0.373 0.62 0.627 RG", index = 16},
  chartreuse = { model="rgb", r="0.498" , g="1" , b="0" , pdfstring = "0.498 1 0 rg 0.498 1 0 RG", index = 17},
  chocolate = { model="rgb", r="0.824" , g="0.412" , b="0.118" , pdfstring = "0.824 0.412 0.118 rg 0.824 0.412 0.118 RG", index = 18},
  coral = { model="rgb", r="1" , g="0.498" , b="0.314" , pdfstring = "1 0.498 0.314 rg 1 0.498 0.314 RG", index = 19},
  cornflowerblue = { model="rgb", r="0.392" , g="0.584" , b="0.929" , pdfstring = "0.392 0.584 0.929 rg 0.392 0.584 0.929 RG", index = 20},
  cornsilk = { model="rgb", r="1" , g="0.973" , b="0.863" , pdfstring = "1 0.973 0.863 rg 1 0.973 0.863 RG", index = 21},
  crimson = { model="rgb", r="0.863" , g="0.078" , b="0.235" , pdfstring = "0.863 0.078 0.235 rg 0.863 0.078 0.235 RG", index = 22},
  darkblue = { model="rgb", r="0" , g="0" , b="0.545" , pdfstring = "0 0 0.545 rg 0 0 0.545 RG", index = 23},
  darkcyan = { model="rgb", r="0" , g="0.545" , b="0.545" , pdfstring = "0 0.545 0.545 rg 0 0.545 0.545 RG", index = 24},
  darkgoldenrod = { model="rgb", r="0.722" , g="0.525" , b="0.043" , pdfstring = "0.722 0.525 0.043 rg 0.722 0.525 0.043 RG", index = 25},
  darkgray = { model="rgb", r="0.663" , g="0.663" , b="0.663" , pdfstring = "0.663 0.663 0.663 rg 0.663 0.663 0.663 RG", index = 26},
  darkgreen = { model="rgb", r="0" , g="0.392" , b="0" , pdfstring = "0 0.392 0 rg 0 0.392 0 RG", index = 27},
  darkgrey = { model="rgb", r="0.663" , g="0.663" , b="0.663" , pdfstring = "0.663 0.663 0.663 rg 0.663 0.663 0.663 RG", index = 28},
  darkkhaki = { model="rgb", r="0.741" , g="0.718" , b="0.42" , pdfstring = "0.741 0.718 0.42 rg 0.741 0.718 0.42 RG", index = 29},
  darkmagenta = { model="rgb", r="0.545" , g="0" , b="0.545" , pdfstring = "0.545 0 0.545 rg 0.545 0 0.545 RG", index = 30},
  darkolivegreen = { model="rgb", r="0.333" , g="0.42" , b="0.184" , pdfstring = "0.333 0.42 0.184 rg 0.333 0.42 0.184 RG", index = 31},
  darkorange = { model="rgb", r="1" , g="0.549" , b="0" , pdfstring = "1 0.549 0 rg 1 0.549 0 RG", index = 32},
  darkorchid = { model="rgb", r="0.6" , g="0.196" , b="0.8" , pdfstring = "0.6 0.196 0.8 rg 0.6 0.196 0.8 RG", index = 33},
  darkred = { model="rgb", r="0.545" , g="0" , b="0" , pdfstring = "0.545 0 0 rg 0.545 0 0 RG", index = 34},
  darksalmon = { model="rgb", r="0.914" , g="0.588" , b="0.478" , pdfstring = "0.914 0.588 0.478 rg 0.914 0.588 0.478 RG", index = 35},
  darkseagreen = { model="rgb", r="0.561" , g="0.737" , b="0.561" , pdfstring = "0.561 0.737 0.561 rg 0.561 0.737 0.561 RG", index = 36},
  darkslateblue = { model="rgb", r="0.282" , g="0.239" , b="0.545" , pdfstring = "0.282 0.239 0.545 rg 0.282 0.239 0.545 RG", index = 37},
  darkslategray = { model="rgb", r="0.184" , g="0.31" , b="0.31" , pdfstring = "0.184 0.31 0.31 rg 0.184 0.31 0.31 RG", index = 38},
  darkslategrey = { model="rgb", r="0.184" , g="0.31" , b="0.31" , pdfstring = "0.184 0.31 0.31 rg 0.184 0.31 0.31 RG", index = 39},
  darkturquoise = { model="rgb", r="0" , g="0.808" , b="0.82" , pdfstring = "0 0.808 0.82 rg 0 0.808 0.82 RG", index = 40},
  darkviolet = { model="rgb", r="0.58" , g="0" , b="0.827" , pdfstring = "0.58 0 0.827 rg 0.58 0 0.827 RG", index = 41},
  deeppink = { model="rgb", r="1" , g="0.078" , b="0.576" , pdfstring = "1 0.078 0.576 rg 1 0.078 0.576 RG", index = 42},
  deepskyblue = { model="rgb", r="0" , g="0.749" , b="1" , pdfstring = "0 0.749 1 rg 0 0.749 1 RG", index = 43},
  dimgray = { model="rgb", r="0.412" , g="0.412" , b="0.412" , pdfstring = "0.412 0.412 0.412 rg 0.412 0.412 0.412 RG", index = 44},
  dimgrey = { model="rgb", r="0.412" , g="0.412" , b="0.412" , pdfstring = "0.412 0.412 0.412 rg 0.412 0.412 0.412 RG", index = 45},
  dodgerblue = { model="rgb", r="0.118" , g="0.565" , b="1" , pdfstring = "0.118 0.565 1 rg 0.118 0.565 1 RG", index = 46},
  firebrick = { model="rgb", r="0.698" , g="0.133" , b="0.133" , pdfstring = "0.698 0.133 0.133 rg 0.698 0.133 0.133 RG", index = 47},
  floralwhite = { model="rgb", r="1" , g="0.98" , b="0.941" , pdfstring = "1 0.98 0.941 rg 1 0.98 0.941 RG", index = 48},
  forestgreen = { model="rgb", r="0.133" , g="0.545" , b="0.133" , pdfstring = "0.133 0.545 0.133 rg 0.133 0.545 0.133 RG", index = 49},
  fuchsia = { model="rgb", r="1" , g="0" , b="1" , pdfstring = "1 0 1 rg 1 0 1 RG", index = 50},
  gainsboro = { model="rgb", r="0.863" , g="0.863" , b="0.863" , pdfstring = "0.863 0.863 0.863 rg 0.863 0.863 0.863 RG", index = 51},
  ghostwhite = { model="rgb", r="0.973" , g="0.973" , b="1" , pdfstring = "0.973 0.973 1 rg 0.973 0.973 1 RG", index = 52},
  gold = { model="rgb", r="1" , g="0.843" , b="0" , pdfstring = "1 0.843 0 rg 1 0.843 0 RG", index = 53},
  goldenrod = { model="rgb", r="0.855" , g="0.647" , b="0.125" , pdfstring = "0.855 0.647 0.125 rg 0.855 0.647 0.125 RG", index = 54},
  gray = { model="rgb", r="0.502" , g="0.502" , b="0.502" , pdfstring = "0.502 0.502 0.502 rg 0.502 0.502 0.502 RG", index = 55},
  green = { model="rgb", r="0" , g="0.502" , b="0" , pdfstring = "0 0.502 0 rg 0 0.502 0 RG", index = 56},
  greenyellow = { model="rgb", r="0.678" , g="1" , b="0.184" , pdfstring = "0.678 1 0.184 rg 0.678 1 0.184 RG", index = 57},
  grey = { model="rgb", r="0.502" , g="0.502" , b="0.502" , pdfstring = "0.502 0.502 0.502 rg 0.502 0.502 0.502 RG", index = 58},
  honeydew = { model="rgb", r="0.941" , g="1" , b="0.941" , pdfstring = "0.941 1 0.941 rg 0.941 1 0.941 RG", index = 59},
  hotpink = { model="rgb", r="1" , g="0.412" , b="0.706" , pdfstring = "1 0.412 0.706 rg 1 0.412 0.706 RG", index = 60},
  indianred = { model="rgb", r="0.804" , g="0.361" , b="0.361" , pdfstring = "0.804 0.361 0.361 rg 0.804 0.361 0.361 RG", index = 61},
  indigo = { model="rgb", r="0.294" , g="0" , b="0.51" , pdfstring = "0.294 0 0.51 rg 0.294 0 0.51 RG", index = 62},
  ivory = { model="rgb", r="1" , g="1" , b="0.941" , pdfstring = "1 1 0.941 rg 1 1 0.941 RG", index = 63},
  khaki = { model="rgb", r="0.941" , g="0.902" , b="0.549" , pdfstring = "0.941 0.902 0.549 rg 0.941 0.902 0.549 RG", index = 64},
  lavender = { model="rgb", r="0.902" , g="0.902" , b="0.98" , pdfstring = "0.902 0.902 0.98 rg 0.902 0.902 0.98 RG", index = 65},
  lavenderblush = { model="rgb", r="1" , g="0.941" , b="0.961" , pdfstring = "1 0.941 0.961 rg 1 0.941 0.961 RG", index = 66},
  lawngreen = { model="rgb", r="0.486" , g="0.988" , b="0" , pdfstring = "0.486 0.988 0 rg 0.486 0.988 0 RG", index = 67},
  lemonchiffon = { model="rgb", r="1" , g="0.98" , b="0.804" , pdfstring = "1 0.98 0.804 rg 1 0.98 0.804 RG", index = 68},
  lightblue = { model="rgb", r="0.678" , g="0.847" , b="0.902" , pdfstring = "0.678 0.847 0.902 rg 0.678 0.847 0.902 RG", index = 69},
  lightcoral = { model="rgb", r="0.941" , g="0.502" , b="0.502" , pdfstring = "0.941 0.502 0.502 rg 0.941 0.502 0.502 RG", index = 70},
  lightcyan = { model="rgb", r="0.878" , g="1" , b="1" , pdfstring = "0.878 1 1 rg 0.878 1 1 RG", index = 71},
  lightgoldenrodyellow = { model="rgb", r="0.98" , g="0.98" , b="0.824" , pdfstring = "0.98 0.98 0.824 rg 0.98 0.98 0.824 RG", index = 72},
  lightgray = { model="rgb", r="0.827" , g="0.827" , b="0.827" , pdfstring = "0.827 0.827 0.827 rg 0.827 0.827 0.827 RG", index = 73},
  lightgreen = { model="rgb", r="0.565" , g="0.933" , b="0.565" , pdfstring = "0.565 0.933 0.565 rg 0.565 0.933 0.565 RG", index = 74},
  lightgrey = { model="rgb", r="0.827" , g="0.827" , b="0.827" , pdfstring = "0.827 0.827 0.827 rg 0.827 0.827 0.827 RG", index = 75},
  lightpink = { model="rgb", r="1" , g="0.714" , b="0.757" , pdfstring = "1 0.714 0.757 rg 1 0.714 0.757 RG", index = 76},
  lightsalmon = { model="rgb", r="1" , g="0.627" , b="0.478" , pdfstring = "1 0.627 0.478 rg 1 0.627 0.478 RG", index = 77},
  lightseagreen = { model="rgb", r="0.125" , g="0.698" , b="0.667" , pdfstring = "0.125 0.698 0.667 rg 0.125 0.698 0.667 RG", index = 78},
  lightskyblue = { model="rgb", r="0.529" , g="0.808" , b="0.98" , pdfstring = "0.529 0.808 0.98 rg 0.529 0.808 0.98 RG", index = 79},
  lightslategray = { model="rgb", r="0.467" , g="0.533" , b="0.6" , pdfstring = "0.467 0.533 0.6 rg 0.467 0.533 0.6 RG", index = 80},
  lightslategrey = { model="rgb", r="0.467" , g="0.533" , b="0.6" , pdfstring = "0.467 0.533 0.6 rg 0.467 0.533 0.6 RG", index = 81},
  lightsteelblue = { model="rgb", r="0.69" , g="0.769" , b="0.871" , pdfstring = "0.69 0.769 0.871 rg 0.69 0.769 0.871 RG", index = 82},
  lightyellow = { model="rgb", r="1" , g="1" , b="0.878" , pdfstring = "1 1 0.878 rg 1 1 0.878 RG", index = 83},
  lime = { model="rgb", r="0" , g="1" , b="0" , pdfstring = "0 1 0 rg 0 1 0 RG", index = 84},
  limegreen = { model="rgb", r="0.196" , g="0.804" , b="0.196" , pdfstring = "0.196 0.804 0.196 rg 0.196 0.804 0.196 RG", index = 85},
  linen = { model="rgb", r="0.98" , g="0.941" , b="0.902" , pdfstring = "0.98 0.941 0.902 rg 0.98 0.941 0.902 RG", index = 86},
  maroon = { model="rgb", r="0.502" , g="0" , b="0" , pdfstring = "0.502 0 0 rg 0.502 0 0 RG", index = 87},
  mediumaquamarine = { model="rgb", r="0.4" , g="0.804" , b="0.667" , pdfstring = "0.4 0.804 0.667 rg 0.4 0.804 0.667 RG", index = 88},
  mediumblue = { model="rgb", r="0" , g="0" , b="0.804" , pdfstring = "0 0 0.804 rg 0 0 0.804 RG", index = 89},
  mediumorchid = { model="rgb", r="0.729" , g="0.333" , b="0.827" , pdfstring = "0.729 0.333 0.827 rg 0.729 0.333 0.827 RG", index = 90},
  mediumpurple = { model="rgb", r="0.576" , g="0.439" , b="0.859" , pdfstring = "0.576 0.439 0.859 rg 0.576 0.439 0.859 RG", index = 91},
  mediumseagreen = { model="rgb", r="0.235" , g="0.702" , b="0.443" , pdfstring = "0.235 0.702 0.443 rg 0.235 0.702 0.443 RG", index = 92},
  mediumslateblue = { model="rgb", r="0.482" , g="0.408" , b="0.933" , pdfstring = "0.482 0.408 0.933 rg 0.482 0.408 0.933 RG", index = 93},
  mediumspringgreen = { model="rgb", r="0" , g="0.98" , b="0.604" , pdfstring = "0 0.98 0.604 rg 0 0.98 0.604 RG", index = 94},
  mediumturquoise = { model="rgb", r="0.282" , g="0.82" , b="0.8" , pdfstring = "0.282 0.82 0.8 rg 0.282 0.82 0.8 RG", index = 95},
  mediumvioletred = { model="rgb", r="0.78" , g="0.082" , b="0.522" , pdfstring = "0.78 0.082 0.522 rg 0.78 0.082 0.522 RG", index = 96},
  midnightblue = { model="rgb", r="0.098" , g="0.098" , b="0.439" , pdfstring = "0.098 0.098 0.439 rg 0.098 0.098 0.439 RG", index = 97},
  mintcream = { model="rgb", r="0.961" , g="1" , b="0.98" , pdfstring = "0.961 1 0.98 rg 0.961 1 0.98 RG", index = 98},
  mistyrose = { model="rgb", r="1" , g="0.894" , b="0.882" , pdfstring = "1 0.894 0.882 rg 1 0.894 0.882 RG", index = 99},
  moccasin = { model="rgb", r="1" , g="0.894" , b="0.71" , pdfstring = "1 0.894 0.71 rg 1 0.894 0.71 RG", index = 100},
  navajowhite = { model="rgb", r="1" , g="0.871" , b="0.678" , pdfstring = "1 0.871 0.678 rg 1 0.871 0.678 RG", index = 101},
  navy = { model="rgb", r="0" , g="0" , b="0.502" , pdfstring = "0 0 0.502 rg 0 0 0.502 RG", index = 102},
  oldlace = { model="rgb", r="0.992" , g="0.961" , b="0.902" , pdfstring = "0.992 0.961 0.902 rg 0.992 0.961 0.902 RG", index = 103},
  olive = { model="rgb", r="0.502" , g="0.502" , b="0" , pdfstring = "0.502 0.502 0 rg 0.502 0.502 0 RG", index = 104},
  olivedrab = { model="rgb", r="0.42" , g="0.557" , b="0.137" , pdfstring = "0.42 0.557 0.137 rg 0.42 0.557 0.137 RG", index = 105},
  orangered = { model="rgb", r="1" , g="0.271" , b="0" , pdfstring = "1 0.271 0 rg 1 0.271 0 RG", index = 106},
  orchid = { model="rgb", r="0.855" , g="0.439" , b="0.839" , pdfstring = "0.855 0.439 0.839 rg 0.855 0.439 0.839 RG", index = 107},
  palegoldenrod = { model="rgb", r="0.933" , g="0.91" , b="0.667" , pdfstring = "0.933 0.91 0.667 rg 0.933 0.91 0.667 RG", index = 108},
  palegreen = { model="rgb", r="0.596" , g="0.984" , b="0.596" , pdfstring = "0.596 0.984 0.596 rg 0.596 0.984 0.596 RG", index = 109},
  paleturquoise = { model="rgb", r="0.686" , g="0.933" , b="0.933" , pdfstring = "0.686 0.933 0.933 rg 0.686 0.933 0.933 RG", index = 110},
  palevioletred = { model="rgb", r="0.859" , g="0.439" , b="0.576" , pdfstring = "0.859 0.439 0.576 rg 0.859 0.439 0.576 RG", index = 111},
  papayawhip = { model="rgb", r="1" , g="0.937" , b="0.835" , pdfstring = "1 0.937 0.835 rg 1 0.937 0.835 RG", index = 112},
  peachpuff = { model="rgb", r="1" , g="0.855" , b="0.725" , pdfstring = "1 0.855 0.725 rg 1 0.855 0.725 RG", index = 113},
  peru = { model="rgb", r="0.804" , g="0.522" , b="0.247" , pdfstring = "0.804 0.522 0.247 rg 0.804 0.522 0.247 RG", index = 114},
  pink = { model="rgb", r="1" , g="0.753" , b="0.796" , pdfstring = "1 0.753 0.796 rg 1 0.753 0.796 RG", index = 115},
  plum = { model="rgb", r="0.867" , g="0.627" , b="0.867" , pdfstring = "0.867 0.627 0.867 rg 0.867 0.627 0.867 RG", index = 116},
  powderblue = { model="rgb", r="0.69" , g="0.878" , b="0.902" , pdfstring = "0.69 0.878 0.902 rg 0.69 0.878 0.902 RG", index = 117},
  purple = { model="rgb", r="0.502" , g="0" , b="0.502" , pdfstring = "0.502 0 0.502 rg 0.502 0 0.502 RG", index = 118},
  red = { model="rgb", r="1" , g="0" , b="0" , pdfstring = "1 0 0 rg 1 0 0 RG", index = 119},
  rosybrown = { model="rgb", r="0.737" , g="0.561" , b="0.561" , pdfstring = "0.737 0.561 0.561 rg 0.737 0.561 0.561 RG", index = 120},
  royalblue = { model="rgb", r="0.255" , g="0.412" , b="0.882" , pdfstring = "0.255 0.412 0.882 rg 0.255 0.412 0.882 RG", index = 121},
  saddlebrown = { model="rgb", r="0.545" , g="0.271" , b="0.075" , pdfstring = "0.545 0.271 0.075 rg 0.545 0.271 0.075 RG", index = 122},
  salmon = { model="rgb", r="0.98" , g="0.502" , b="0.447" , pdfstring = "0.98 0.502 0.447 rg 0.98 0.502 0.447 RG", index = 123},
  sandybrown = { model="rgb", r="0.957" , g="0.643" , b="0.376" , pdfstring = "0.957 0.643 0.376 rg 0.957 0.643 0.376 RG", index = 124},
  seagreen = { model="rgb", r="0.18" , g="0.545" , b="0.341" , pdfstring = "0.18 0.545 0.341 rg 0.18 0.545 0.341 RG", index = 125},
  seashell = { model="rgb", r="1" , g="0.961" , b="0.933" , pdfstring = "1 0.961 0.933 rg 1 0.961 0.933 RG", index = 126},
  sienna = { model="rgb", r="0.627" , g="0.322" , b="0.176" , pdfstring = "0.627 0.322 0.176 rg 0.627 0.322 0.176 RG", index = 127},
  silver = { model="rgb", r="0.753" , g="0.753" , b="0.753" , pdfstring = "0.753 0.753 0.753 rg 0.753 0.753 0.753 RG", index = 128},
  skyblue = { model="rgb", r="0.529" , g="0.808" , b="0.922" , pdfstring = "0.529 0.808 0.922 rg 0.529 0.808 0.922 RG", index = 129},
  slateblue = { model="rgb", r="0.416" , g="0.353" , b="0.804" , pdfstring = "0.416 0.353 0.804 rg 0.416 0.353 0.804 RG", index = 130},
  slategray = { model="rgb", r="0.439" , g="0.502" , b="0.565" , pdfstring = "0.439 0.502 0.565 rg 0.439 0.502 0.565 RG", index = 131},
  slategrey = { model="rgb", r="0.439" , g="0.502" , b="0.565" , pdfstring = "0.439 0.502 0.565 rg 0.439 0.502 0.565 RG", index = 132},
  snow = { model="rgb", r="1" , g="0.98" , b="0.98" , pdfstring = "1 0.98 0.98 rg 1 0.98 0.98 RG", index = 133},
  springgreen = { model="rgb", r="0" , g="1" , b="0.498" , pdfstring = "0 1 0.498 rg 0 1 0.498 RG", index = 134},
  steelblue = { model="rgb", r="0.275" , g="0.51" , b="0.706" , pdfstring = "0.275 0.51 0.706 rg 0.275 0.51 0.706 RG", index = 135},
  tan = { model="rgb", r="0.824" , g="0.706" , b="0.549" , pdfstring = "0.824 0.706 0.549 rg 0.824 0.706 0.549 RG", index = 136},
  teal = { model="rgb", r="0" , g="0.502" , b="0.502" , pdfstring = "0 0.502 0.502 rg 0 0.502 0.502 RG", index = 137},
  thistle = { model="rgb", r="0.847" , g="0.749" , b="0.847" , pdfstring = "0.847 0.749 0.847 rg 0.847 0.749 0.847 RG", index = 138},
  tomato = { model="rgb", r="1" , g="0.388" , b="0.278" , pdfstring = "1 0.388 0.278 rg 1 0.388 0.278 RG", index = 139},
  turquoise = { model="rgb", r="0.251" , g="0.878" , b="0.816" , pdfstring = "0.251 0.878 0.816 rg 0.251 0.878 0.816 RG", index = 140},
  violet = { model="rgb", r="0.933" , g="0.51" , b="0.933" , pdfstring = "0.933 0.51 0.933 rg 0.933 0.51 0.933 RG", index = 141},
  wheat = { model="rgb", r="0.961" , g="0.871" , b="0.702" , pdfstring = "0.961 0.871 0.702 rg 0.961 0.871 0.702 RG", index = 142},
  white = { model="gray", g="1" , pdfstring = "1 G 1 g", index = 143},
  whitesmoke = { model="rgb", r="0.961" , g="0.961" , b="0.961" , pdfstring = "0.961 0.961 0.961 rg 0.961 0.961 0.961 RG", index = 144},
  yellow = { model="rgb", r="1" , g="1" , b="0" , pdfstring = "1 1 0 rg 1 1 0 RG", index = 145},
  yellowgreen = { model="rgb", r="0.604" , g="0.804" , b="0.196" , pdfstring = "0.604 0.804 0.196 rg 0.604 0.804 0.196 RG", index = 146},
  ["-"] = { pdfstring = " ", index = 147 }
}

-- An array of defined colors
---@type string[]
M.colortable = {"black","aliceblue", "orange", "rebeccapurple", "antiquewhite", "aqua", "aquamarine", "azure", "beige", "bisque", "blanchedalmond", "blue", "blueviolet", "brown", "burlywood", "cadetblue", "chartreuse", "chocolate", "coral", "cornflowerblue", "cornsilk", "crimson", "darkblue", "darkcyan", "darkgoldenrod", "darkgray", "darkgreen", "darkgrey", "darkkhaki", "darkmagenta", "darkolivegreen", "darkorange", "darkorchid", "darkred", "darksalmon", "darkseagreen", "darkslateblue", "darkslategray", "darkslategrey", "darkturquoise", "darkviolet", "deeppink", "deepskyblue", "dimgray", "dimgrey", "dodgerblue", "firebrick", "floralwhite", "forestgreen", "fuchsia", "gainsboro", "ghostwhite", "gold", "goldenrod", "gray", "green", "greenyellow", "grey", "honeydew", "hotpink", "indianred", "indigo", "ivory", "khaki", "lavender", "lavenderblush", "lawngreen", "lemonchiffon", "lightblue", "lightcoral", "lightcyan", "lightgoldenrodyellow", "lightgray", "lightgreen", "lightgrey", "lightpink", "lightsalmon", "lightseagreen", "lightskyblue", "lightslategray", "lightslategrey", "lightsteelblue", "lightyellow", "lime", "limegreen", "linen", "maroon", "mediumaquamarine", "mediumblue", "mediumorchid", "mediumpurple", "mediumseagreen", "mediumslateblue", "mediumspringgreen", "mediumturquoise", "mediumvioletred", "midnightblue", "mintcream", "mistyrose", "moccasin", "navajowhite", "navy", "oldlace", "olive", "olivedrab", "orangered", "orchid", "palegoldenrod", "palegreen", "paleturquoise", "palevioletred", "papayawhip", "peachpuff", "peru", "pink", "plum", "powderblue", "purple", "red", "rosybrown", "royalblue", "saddlebrown", "salmon", "sandybrown", "seagreen", "seashell", "sienna", "silver", "skyblue", "slateblue", "slategray", "slategrey", "snow", "springgreen", "steelblue", "tan", "teal", "thistle", "tomato", "turquoise", "violet", "wheat", "white", "whitesmoke", "yellow", "yellowgreen", "-"}

-- Parses a CSS-like color value into normalized channels.
-- Accepts `#rgb`, `#rrggbb`, `rgb(...)`, or `rgba(...)` strings.
---@param colorvalue string CSS color value.
---@return number r Red component in [0,1].
---@return number g Green component in [0,1].
---@return number b Blue component in [0,1].
---@return number? a Alpha percentage in [0,100] or `nil` if not provided.
function M.getrgb( colorvalue )
    local r,g,b,a
    local rgbstr = "^rgba?%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)$"
    local rgbastr = "^rgba?%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d%.%d)%s*%)$"
    if string.sub(colorvalue,1,3) == "rgb" then
        if string.match(colorvalue, rgbstr) then
            r,g,b = string.match(colorvalue, rgbstr)
        elseif string.match(colorvalue, rgbastr) then
            r,g,b,a = string.match(colorvalue, rgbastr)
        else
            -- w("don't know")
        end
        if r == nil then
            main.log("error", string.format("Could not parse color %q", colorvalue))
            return 0,0,0
        end
        r = math.round(r / 255 , 3)
        g = math.round(g / 255 , 3)
        b = math.round(b / 255 , 3)
        if a then a = a * 100 end
    elseif #colorvalue == 7 then
        r,g,b = string.match(colorvalue,"#?(%x%x)(%x%x)(%x%x)")
        r = math.round(tonumber(r,16) / 255, 3)
        g = math.round(tonumber(g,16) / 255, 3)
        b = math.round(tonumber(b,16) / 255, 3)
    elseif #colorvalue == 4 then
        r,g,b = string.match(colorvalue,"#?(%x)(%x)(%x)")
        r = math.round(tonumber(r,16) / 15, 3)
        g = math.round(tonumber(g,16) / 15, 3)
        b = math.round(tonumber(b,16) / 15, 3)
    else
        main.log("error", string.format("Could not parse color %q", colorvalue))
        return 0,0,0
    end
    return r,g,b,a
end

setmetatable(M.colors,{  __index = function (tbl,key)
    if not key then
        main.log("error", "Empty color")
        return tbl["black"]
    end
    if string.sub(key,1,1) ~= "#" and string.sub(key,1,3) ~= "rgb" then
        return nil
    end
    main.log("info","Define color","name",key)
    local color = {}
    color.r, color.g, color.b = M.getrgb(key)
    color.pdfstring = string.format("%g %g %g rg %g %g %g RG", color.r, color.g, color.b, color.r,color.g, color.b)
    color.overprint = false
    color.model = "rgb"
    M.colortable[#M.colortable + 1] = key
    color.index = #M.colortable
    rawset(tbl,key,color)
    return color
end
 })

-- Collects all spot colors used so far so the page resources can be built.
---@param num integer Spot color id.
local function usespotcolor(num)
    M.used_spotcolors[num] = true
end
M.usespotcolor = usespotcolor

-- Splits a combined PDF color string into its fill and stroke parts.
---@param pdfcolor string Combined PDF color command.
---@return string? fill Fill command, or `nil` if no match.
---@return string? stroke Stroke command, or `nil` if no match.
function M.fill_stroke_color( pdfcolor )
    local a,b = string.match(pdfcolor,"^(.*rg)(.*RG)")
    if a ~= nil then
        return a,b
    end
    a,b = string.match(pdfcolor,"^(.*k)(.*K)")
    if a ~= nil then
        return a,b
    end
    a,b = string.match(pdfcolor,"^(.*G)(.*g)")
    return a,b
end

-- Metatable `__index` for color entries that derives PDF strings on demand.
---@param tbl Color Color entry.
---@param idx "pdfstring"|"pdfstring_fill"|"pdfstring_stroking" Requested field.
---@return string? value Derived PDF command, or `nil` if not applicable.
local function colentry_index_function(tbl,idx)
    local model = rawget(tbl,"model")
    if model == "spotcolor" then
        local saturation = math.round(tbl.saturation,3)
        if idx == "pdfstring" then
            usespotcolor(tbl.colornum)
            local op
            if tbl.overprint then
                op = "/GS0 gs"
            else
                op = ""
            end
            local ret = string.format("%s /CS%d CS /CS%d cs %g scn ",op,tbl.colornum, tbl.colornum,saturation)
            return ret
        elseif idx == "pdfstring_stroking" then
            usespotcolor(tbl.colornum)
            local op
            if tbl.overprint then
                op = "/GS0 gs"
            else
                op = ""
            end
            local ret = string.format("%s /CS%d CS %g scn ",op,tbl.colornum,saturation)
            return ret
        elseif idx == "pdfstring_fill" then
            usespotcolor(tbl.colornum)
            local op
            if tbl.overprint then
                op = "/GS0 gs"
            else
                op = ""
            end
            local ret = string.format("%s /CS%d cs %g scn ",op,tbl.colornum,saturation)
            return ret
        end
    elseif idx == "pdfstring_stroking" then
        local _,b = M.fill_stroke_color(rawget(tbl,"pdfstring"))
        return b
    elseif idx == "pdfstring_fill" then
        local a,_ = M.fill_stroke_color(rawget(tbl,"pdfstring"))
        return a
    -- elseif idx == "pdfstring" then
    --     return rawget(tbl,"pdfstring")
    end
end

-- used in DefineColor
-- M.colentry_index_function = colentry_index_function
---@type metatable
M.colormetatable = {__index = colentry_index_function}

-- Gets the PDF color string for a color name or `colortable` index.
---@param colorname_or_number string|integer Color name or 1-based index into `colortable`.
---@return string? pdfcommand PDF color command, or `nil` if not resolvable.
function M.pdfstring_from_color(colorname_or_number)
    local colorname
    local colno = tonumber(colorname_or_number)
    if colno then
        colorname = M.colortable[colno]
    else
        colorname = tostring(colorname_or_number)
    end
    local colentry = M.get_colentry_from_name(colorname,"black")
    if colentry then return colentry.pdfstring else return nil end
end

-- Resolves a color entry by name, falling back to `default` and finally to black.
-- The returned entry is wrapped with `colormetatable` for lazy PDF strings.
---@param colorname string? Requested color name.
---@param default string? Fallback color name if `colorname` is `nil` or unknown.
---@return Color color Color entry; black if everything else fails.
function M.get_colentry_from_name(colorname, default)
    colorname = colorname or default
    local colentry
    if colorname then
        if not M.colors[colorname] then
            if default then
                main.log("error","Color is not defined yet","name",colorname)
            else
                colentry = nil
            end
        else
            colentry = M.colors[colorname]
        end
    end
    if not colentry then
        main.log("error","Undefined color, revert to black","value",colorname or "(undefined)")
        return M.colors["black"]
    end
    return setmetatable(colentry, M.colormetatable)
end

-- Gets the `colortable` index for a color name.
---@param colorname string? Requested color name.
---@param default string? Fallback color name.
---@return integer? index Color index, or `nil` if not resolvable.
function M.get_colorindex_from_name(colorname, default)
    if not colorname then return nil end
    if colorname == "nil" then return nil end
    local colentry = M.get_colentry_from_name(colorname,default)
    if colentry then return colentry.index else return nil end
end

-- Registers a new color name in `colortable`. If the name is already known,
-- the existing index is returned.
---@param name string Color name.
---@return integer index Index of the color in `colortable`.
function M.register_color( name )
    if M.colors[name] ~= nil then
        return M.colors[name].index
    end
    M.colortable[#M.colortable + 1] = name
    return #M.colortable
end

file_end("publisher/colors.lua")

return M
