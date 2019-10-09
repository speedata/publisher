--- The initialization file. The first file to be called from the TeX file. Be aware that `sdini.lua` is
--- called from `luatex --lua ...` before this file.
--
--  spinit.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.



-- file_start("spinit.lua")
local u8fix = require('utf8fix')

tex.enableprimitives('',tex.extraprimitives ())
-- Lua 5.2 has table.unpack
unpack = unpack or table.unpack

function warning(...)
    local text = { ... }
    local unpacked = string.format( "[page %d] ",publisher.current_pagenumber ) .. string.format(unpack(text))
    publisher.messages[#publisher.messages + 1] = { unpacked , "warning" }
    errorlog:write("Warning: " .. unpacked .. "\n")
    texio.write("Warning: " .. unpacked .. "\n")
end

local errcount=0
function err(...)
    local text = { ... }
    local errorcode = 1
    -- if first arg is a number, this is the error code
    if type(text[1]) == "number" then
        errorcode = table.remove(text,1)
    end
    local unpacked = string.format( "[page %d] ",publisher.current_pagenumber ) .. string.format(unpack(text))
    publisher.messages[#publisher.messages + 1] = { unpacked , "error", errorcode }
    errcount =  errcount + 1
    errorlog:write("Error: " .. unpacked .. "\n")
    texio.write("Error: " .. unpacked .. "\n")
end

function call(...)
    local ret = { pcall(...) }
    if ret[1]==false then
        err(tostring(ret[2])  .. "\n" .. debug.traceback())
        return
    end
    return unpack(ret,2)
end

function log(...)
    local text = { ... }
    local res = call(string.format,unpack(text))
    texio.write(res .. "\n")
    if io.type(errorlog) == "file" then
        errorlog:write(res .. "\n")
    end
end

function synclog()
    io.stdout:flush()
end

do
local matches = {
    ["^"] = "%^";
    ["$"] = "%$";
    ["("] = "%(";
    [")"] = "%)";
    ["%"] = "%%";
    ["."] = "%.";
    ["["] = "%[";
    ["]"] = "%]";
    ["*"] = "%*";
    ["+"] = "%+";
    ["-"] = "%-";
    ["?"] = "%?";
    ["\0"] = "%z";
}
escape_lua_pattern = function(s)
    return (s:gsub(".", matches))
    end
end

--- Convert scaled point to postscript points,
--- rounded to three digits after decimal point
function sp_to_bp( sp )
    return math.round(sp / 65782 , 3)
end

function sp_to_pt( sp )
    return math.round(sp / 65536 , 3)
end

--- Sum up the contents of the array entries. `first` and `last` are optional.
function table.sum( tbl, first, last )
    local sum = 0
    first = first or 1
    last  = last  or #tbl
    for i=first,last do
        sum = sum + tbl[i]
    end
    return sum
end

-- tbl .. tbl
function table.__concat( tbl, other )
    if type(other) ~= "table" then
        err("Internal error: table concat: second argument is not a table")
        return
    end
    local ret = {}
    for i=1,#tbl do
        ret[#ret + 1] = tbl[i]
    end
    for i=1,#other do
        ret[#ret + 1] = other[i]
    end
    return ret
end

-- Get the text value of a table. Only the indexes 1,...#table are taken into account.
-- The function recurses into nested tables.
function table_textvalue( tbl )
    if not tbl then return nil end
    if type(tbl) ~= "table" then return tostring(tbl) end
    local ret = {}
    for _,v in ipairs(tbl) do
        if type(v) == "string" then
            ret[#ret + 1] = v
        elseif type(v) == "table" then
            ret[#ret + 1] = table_textvalue(v)
        end
    end
    return table.concat(ret)
end

--- Round the given `num` to `idp` digits. From [the Lua wiki](http://lua-users.org/wiki/SimpleRound)
function math.round(num, idp)
    if idp and idp>0 then
        local mult = 10^idp
        return math.floor(num * mult + 0.5) / mult
    end
    return math.floor(num + 0.5)
end

function set_glue( gluenode, values )
    local n
    if gluenode == nil then
        n = node.new("glue")
    else
        n = gluenode
    end
    local spec

    if node.has_field(n,"spec") then
        spec = node.new("glue_spec")
        n.spec = spec
    else
        spec = n
    end
    values = values or {}
    for k,v in pairs(values) do
        spec[k] = v
    end
    return n
end

function set_glue_values( n , values)
    local spec

    if node.has_field(n,"spec") then
        spec = n.spec
    else
        spec = n
    end

    for k,v in pairs(values) do
        spec[k]=v
    end

end

function get_glue_value( n, value )
    local spec
    if node.has_field(n,"spec") then
        spec = n.spec
    else
        spec = n
    end
    return spec[value]
end

--- This is like the original `tex.sp` except that it changes `pt` to `bp` and `pp` to `pt`.
--- We do that because in the dtp world when we say 12pt, we always mean 12*1/72 inch.
local orig_texsp = tex.sp
function tex.sp( number_or_string )
    if number_or_string == "0" or number_or_string == 0 then
        return 0
    end

    if type(number_or_string) == "string" then
        local tmp = string.gsub(number_or_string,"(%d)pt","%1bp"):gsub("(%d)pp","%1pt")
        local ret = { pcall(orig_texsp,tmp) }
        if ret[1]==false then
            err("Could not convert dimension %q",number_or_string)
            return nil
        end
        return unpack(ret,2)
    end
    return orig_texsp(number_or_string)
end

local _assert = assert
function assert( what,msg)
  if not what then
    texio.write_nl("An error occurred: " .. (msg or "") )
    texio.write_nl(debug.traceback())
  end
  return what
end

local function fixup_msg(msg)
    msg = publisher.xml_escape(msg)
    -- The message can be in a non-UTF-8 encoding. See #65
    msg = u8fix.sanitize(msg)
    return msg
end

---   I/O, Control flow
--- -------------------

--- Stop the data processing and write PDF. If `graceful` is not given or `false` then
--- `os.exit()` gets called. This is the last function to be called.
function exit(graceful)
    log("Stop processing data")
    log("%d errors occurred",errcount)
    log("Duration: %3f seconds",os.gettimeofday() - starttime)
    errorlog:write("---------------------------------------------\n")
    errorlog:write(string.format("Duration: %3f seconds\n",os.gettimeofday() - starttime))
    errorlog:close()
    statusfile = io.open(string.format("%s.status",tex.jobname),"wb")
    statusfile:write(string.format("<Status>\n  <Errors>%d</Errors>\n",errcount))
    local msgs = publisher.messages
    for i=1,#msgs do
        if msgs[i][2] == "error" then
            statusfile:write(string.format("  <Error code='%d'>%s</Error>\n", msgs[i][3] or 1,fixup_msg(msgs[i][1])))
        elseif msgs[i][2] == "message" then
            statusfile:write(string.format("  <Message>%s</Message>\n",fixup_msg(msgs[i][1])))
        elseif msgs[i][2] == "warning" then
            statusfile:write(string.format("  <Warning>%s</Warning>\n",fixup_msg(msgs[i][1])))
        elseif msgs[i][2] == "element" then
            statusfile:write(string.format("  %s\n",publisher.xml_to_string(msgs[i][1])))
        end
    end
    statusfile:write(string.format("  <DurationSeconds>%d</DurationSeconds>\n",math.ceil(os.gettimeofday() - starttime)))
    statusfile:write("</Status>")
    statusfile:close()
    if not graceful then
        os.exit()
    end
end

function quit()
    os.exit(-1)
end

local function setup()
    if status.luatex_version >= 100 then
        tex.pdfhorigin = 0
        tex.pdfvorigin = 0
        pdf.setminorversion(6)
        pdf.setsuppressoptionalinfo(143)
        pdf.setcompresslevel(9)
        pdf.setobjcompresslevel(9)
    else
        tex.hoffset       = tex.sp("-1in")
        tex.voffset       = tex.hoffset
        tex.pdfcompresslevel    = 5
        tex.pdfobjcompresslevel = 2
        tex.pdfminorversion = 6
    end
    tex.pdfadjustspacing = 2
    tex.adjustspacing = 2
    tex.pdfpageheight = tex.sp("29.7cm")
    tex.pdfpagewidth  = tex.sp("21cm")
    tex.pdfprotrudechars = 2 -- margin protrusion
    tex.protrudechars = 2 -- margin protrusion
    tex.pdfoutput=1
    tex.outputmode = 1
    tex.lefthyphenmin  = 2
    tex.righthyphenmin = 3
    tex.hfuzz    = publisher.maxdimen
    tex.vfuzz    = publisher.maxdimen
    tex.hbadness = publisher.maxdimen
    tex.vbadness = publisher.maxdimen
    --- The `lccode` is used for hyphenation. TeX sets the lccode for a-z to itself and A-Z to its lower correspondent.
    --- The code for all other characters are not set and thus they don't hyphenate unless set like this.
    for _,i in ipairs
        {181,223,224,225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244,245,246,248,249,250,251,252,
        253,254,255,257,259,261,263,265,267,269,271,273,275,277,279,281,283,285,287,289,291,293,295,297,299,301,303,305,307,309,
        311,314,316,318,320,322,324,326,328,331,333,335,337,339,341,343,345,347,349,351,353,355,357,359,361,363,365,367,369,371,
        373,375,378,380,382,383,384,387,389,392,396,402,405,409,410,414,417,419,421,424,429,432,436,438,441,445,447,454,457,460,
        462,464,466,468,470,472,474,476,477,479,481,483,485,487,489,491,493,495,499,501,505,507,509,511,513,515,517,519,521,523,
        525,527,529,531,533,535,537,539,541,543,547,549,551,553,555,557,559,561,563,572,578,583,585,587,589,591,592,593,595,596,
        598,599,601,603,608,611,616,617,619,623,625,626,629,637,640,643,648,649,650,651,652,658,881,883,887,891,892,893,940,941,
        942,943,945,946,947,948,949,950,951,952,953,954,955,956,957,958,959,960,961,962,963,964,965,966,967,968,969,970,971,972,
        973,974,976,977,981,982,983,985,987,989,991,993,995,997,999,1001,1003,1005,1007,1008,1009,1010,1013,1016,1019,1072,1073,1074,1075,1076,
        1077,1078,1079,1080,1081,1082,1083,1084,1085,1086,1087,1088,1089,1090,1091,1092,1093,1094,1095,1096,1097,1098,1099,1100,1101,1102,1103,1104,1105,1106,
        1107,1108,1109,1110,1111,1112,1113,1114,1115,1116,1117,1118,1119,1121,1123,1125,1127,1129,1131,1133,1135,1137,1139,1141,1143,1145,1147,1149,1151,1153,
        1163,1165,1167,1169,1171,1173,1175,1177,1179,1181,1183,1185,1187,1189,1191,1193,1195,1197,1199,1201,1203,1205,1207,1209,1211,1213,1215,1218,1220,1222,
        1224,1226,1228,1230,1231,1233,1235,1237,1239,1241,1243,1245,1247,1249,1251,1253,1255,1257,1259,1261,1263,1265,1267,1269,1271,1273,1275,1277,1279,1281,
        1283,1285,1287,1289,1291,1293,1295,1297,1299,1301,1303,1305,1307,1309,1311,1313,1315}
    do
        tex.lccode[i] = i
    end
    for _,i in ipairs
        {{192, 224},{193, 225},{194, 226},{195, 227},{196, 228},{197, 229},{198, 230},{199, 231},{200, 232},{201, 233},{202, 234},
        {203, 235},{204, 236},{205, 237},{206, 238},{207, 239},{208, 240},{209, 241},{210, 242},{211, 243},{212, 244},{213, 245},{214, 246},
        {216, 248},{217, 249},{218, 250},{219, 251},{220, 252},{221, 253},{222, 254},{256, 257},{258, 259},{260, 261},{262, 263},{264, 265},
        {266, 267},{268, 269},{270, 271},{272, 273},{274, 275},{276, 277},{278, 279},{280, 281},{282, 283},{284, 285},{286, 287},{288, 289},
        {290, 291},{292, 293},{294, 295},{296, 297},{298, 299},{300, 301},{302, 303},{304, 105},{306, 307},{308, 309},{310, 311},{313, 314},
        {315, 316},{317, 318},{319, 320},{321, 322},{323, 324},{325, 326},{327, 328},{330, 331},{332, 333},{334, 335},{336, 337},{338, 339},
        {340, 341},{342, 343},{344, 345},{346, 347},{348, 349},{350, 351},{352, 353},{354, 355},{356, 357},{358, 359},{360, 361},{362, 363},
        {364, 365},{366, 367},{368, 369},{370, 371},{372, 373},{374, 375},{376, 255},{377, 378},{379, 380},{381, 382},{385, 595},{386, 387},
        {388, 389},{390, 596},{391, 392},{393, 598},{394, 599},{395, 396},{398, 477},{399, 601},{400, 603},{401, 402},{403, 608},{404, 611},
        {406, 617},{407, 616},{408, 409},{412, 623},{413, 626},{415, 629},{416, 417},{418, 419},{420, 421},{422, 640},{423, 424},{425, 643},
        {428, 429},{430, 648},{431, 432},{433, 650},{434, 651},{435, 436},{437, 438},{439, 658},{440, 441},{444, 445},{452, 454},{455, 457},
        {458, 460},{461, 462},{463, 464},{465, 466},{467, 468},{469, 470},{471, 472},{473, 474},{475, 476},{478, 479},{480, 481},{482, 483},
        {484, 485},{486, 487},{488, 489},{490, 491},{492, 493},{494, 495},{497, 499},{500, 501},{502, 405},{503, 447},{504, 505},{506, 507},
        {508, 509},{510, 511},{512, 513},{514, 515},{516, 517},{518, 519},{520, 521},{522, 523},{524, 525},{526, 527},{528, 529},{530, 531},
        {532, 533},{534, 535},{536, 537},{538, 539},{540, 541},{542, 543},{544, 414},{546, 547},{548, 549},{550, 551},{552, 553},{554, 555},
        {556, 557},{558, 559},{560, 561},{562, 563},{570, 11365},{571, 572},{573, 410},{574, 11366},{577, 578},{579, 384},{580, 649},{581, 652},
        {582, 583},{584, 585},{586, 587},{588, 589},{590, 591},{880, 881},{882, 883},{886, 887},{902, 940},{904, 941},{905, 942},{906, 943},
        {908, 972},{910, 973},{911, 974},{913, 945},{914, 946},{915, 947},{916, 948},{917, 949},{918, 950},{919, 951},{920, 952},{921, 953},
        {922, 954},{923, 955},{924, 956},{925, 957},{926, 958},{927, 959},{928, 960},{929, 961},{931, 963},{932, 964},{933, 965},{934, 966},
        {935, 967},{936, 968},{937, 969},{938, 970},{939, 971},{975, 983},{984, 985},{986, 987},{988, 989},{990, 991},{992, 993},{994, 995},
        {996, 997},{998, 999},{1000, 1001},{1002, 1003},{1004, 1005},{1006, 1007},{1012, 952},{1015, 1016},{1017, 1010},{1018, 1019},{1021, 891},{1022, 892},
        {1023, 893},{1024, 1104},{1025, 1105},{1026, 1106},{1027, 1107},{1028, 1108},{1029, 1109},{1030, 1110},{1031, 1111},{1032, 1112},{1033, 1113},{1034, 1114},
        {1035, 1115},{1036, 1116},{1037, 1117},{1038, 1118},{1039, 1119},{1040, 1072},{1041, 1073},{1042, 1074},{1043, 1075},{1044, 1076},{1045, 1077},{1046, 1078},
        {1047, 1079},{1048, 1080},{1049, 1081},{1050, 1082},{1051, 1083},{1052, 1084},{1053, 1085},{1054, 1086},{1055, 1087},{1056, 1088},{1057, 1089},{1058, 1090},
        {1059, 1091},{1060, 1092},{1061, 1093},{1062, 1094},{1063, 1095},{1064, 1096},{1065, 1097},{1066, 1098},{1067, 1099},{1068, 1100},{1069, 1101},{1070, 1102},
        {1071, 1103},{1120, 1121},{1122, 1123},{1124, 1125},{1126, 1127},{1128, 1129},{1130, 1131},{1132, 1133},{1134, 1135},{1136, 1137},{1138, 1139},{1140, 1141},
        {1142, 1143},{1144, 1145},{1146, 1147},{1148, 1149},{1150, 1151},{1152, 1153},{1162, 1163},{1164, 1165},{1166, 1167},{1168, 1169},{1170, 1171},{1172, 1173},
        {1174, 1175},{1176, 1177},{1178, 1179},{1180, 1181},{1182, 1183},{1184, 1185},{1186, 1187},{1188, 1189},{1190, 1191},{1192, 1193},{1194, 1195},{1196, 1197},
        {1198, 1199},{1200, 1201},{1202, 1203},{1204, 1205},{1206, 1207},{1208, 1209},{1210, 1211},{1212, 1213},{1214, 1215},{1216, 1231},{1217, 1218},{1219, 1220},
        {1221, 1222},{1223, 1224},{1225, 1226},{1227, 1228},{1229, 1230},{1232, 1233},{1234, 1235},{1236, 1237},{1238, 1239},{1240, 1241},{1242, 1243},{1244, 1245},
        {1246, 1247},{1248, 1249},{1250, 1251},{1252, 1253},{1254, 1255},{1256, 1257},{1258, 1259},{1260, 1261},{1262, 1263},{1264, 1265},{1266, 1267},{1268, 1269},
        {1270, 1271},{1272, 1273},{1274, 1275},{1276, 1277},{1278, 1279},{1280, 1281},{1282, 1283},{1284, 1285},{1286, 1287},{1288, 1289},{1290, 1291},{1292, 1293},
        {1294, 1295},{1296, 1297},{1298, 1299},{1300, 1301},{1302, 1303},{1304, 1305},{1306, 1307},{1308, 1309},{1310, 1311},{1312, 1313},{1314, 1315},{1329, 1377}}
    do
        tex.lccode[i[1]]=i[2]
    end
end

--- This is the entry point in the publishing run and called from the TeX file (`publisher.tex`).
require("publisher")

function main_loop()
    log("Start processing")
    setup()
    call(publisher.dothings)
    exit(true)
end

errorlog = io.open(string.format("%s.protocol",tex.jobname),"ab")
errorlog:write("---------------------------------------------\n")

starttime = os.gettimeofday()

font.cache = 'no'

main_loop()
