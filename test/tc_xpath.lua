
publisher = {}

err = texio.write_nl

publisher.variablen = {
  ["column"]  = "2",
  ["counter"]  = 1,
  ["textvar"] = "yes",
  ["empty"]   = '',
  }
publisher.alternating = {}

local function alternating(dataxml, ... )
  local alt_type = select(1,...)
  if not publisher.alternating[alt_type] then
    publisher.alternating[alt_type] = 1
  else
    publisher.alternating[alt_type] = math.fmod( publisher.alternating[alt_type], select("#",...) - 1 ) + 1
  end
  return select(publisher.alternating[alt_type] + 1 ,...)
end

publisher.sd_xpath_funktionen = { en = {
  ["number_of_columns"]  = function() return 10 end,
  ["groupheight"]        = function(dataxml, tmp) return tmp end,
  ["alternating"]        = alternating,
  ["number_of_datasets"] = function(dataxml, d) local count = 0 d = d[1] for i=1,#d do if type(d[i]) == 'table' then count = count + 1 end end return count end,
  ["even"]               = function(dataxml, arg)  return math.fmod(arg,2) == 0  end,
  ["odd"]                = function(dataxml, arg)  return math.fmod(arg,2) ~= 0  end,
  ["node"]               = function(dataxml) local tab={} for i=1,#dataxml do tab[#tab + 1] = dataxml[i] end return tab end,
  ["true"]               = function() return true end,
  ["false"]              = function() return false end,
  ["variable"]           = function(datanxml,arg) return publisher.variablen[arg] end
}}

module(...,package.seeall)

luxor = do_luafile("luxor.lua")
require("xpath")

local data_src=[[
<root a="1">
 <sub foo="baz">123</sub>
 <sub foo="bar">contents</sub>
</root>
]]

local data = luxor.parse_xml(data_src)
local namespace = { sd = "urn:speedata:2009/publisher/functions/en"}

function test_variable()
  assert_equal(xpath.parse( data, " sd:variable('column') ",namespace ),'2')
  assert_equal(xpath.parse( data, " ( sd:variable('column') ) ",namespace ),'2')
  assert_equal(xpath.parse( data, " ( sd:variable('column') + sd:variable('column') ) ",namespace ),4)
end

-- function test_node()
--   local tmp = xpath.parse( data, " sd:node() ",namespace )
--   --- recursive data structure! nil pointer to parent
--   tmp[2][".__parent"] = nil
--   tmp[4][".__parent"] = nil

--   assert_equal(xpath.parse( data, " sd:node() ",namespace ), 
--     { ' ',
--      {'123',       foo = "baz", [".__name"]="sub"} ,
--       ' ',
--      { 'contents', foo = "bar",[".__name"]="sub"} ,
--       ' '
--      })
-- end

-- function test_nested_funcs( )
--   assert_false(xpath.parse( data, " sd:ungerade( sd:anzahl-spalten()  )" ))
--   assert_true(xpath.parse( data,  " sd:gerade( sd:anzahl-spalten()  )" ))
--   assert_true(xpath.parse( data,  " sd:ungerade( sd:anzahl-spalten() + 1 ) " ))
-- end

function test_anzahldatensaetze()
  assert_equal(xpath.parse( data, " sd:number-of-datasets(.) ",namespace ), 2)
end

function test_orexpr( )
  assert_true(xpath.parse( data, " 2 > 4 or 3 > 5 or 3 > 1",namespace ))
end

function test_andexpr()
  assert_true(xpath.parse( data, " 'a' = 'a' and 'b' = 'b' ",namespace ), true)
  assert_false(xpath.parse( data, " 6 < 4 and 7 > 5 ",namespace ), false)
  assert_true(xpath.parse( data, " 2 < 4 and 7 > 5 ",namespace ), true)
end

function test_alternating()
  assert_equal(xpath.parse( data, " sd:alternating('tmp','a','b','c') ",namespace ), 'a')
  assert_equal(xpath.parse( data, " sd:alternating('tmp','a','b','c') ",namespace ), 'b')
  assert_equal(xpath.parse( data, " sd:alternating('tmp','a','b','c') ",namespace ), 'c')
  assert_equal(xpath.parse( data, " sd:alternating('tmp','a','b','c') ",namespace ), 'a')
  assert_equal(xpath.parse( data, " sd:alternating('tmp','a','b','c') ",namespace ), 'b')
end

function test_stringcomparison()
  assert_equal(xpath.parse( data, " $textvar ",namespace ), 'yes')
  assert_false(xpath.parse( data, " $textvar = 'no'",namespace ))
  assert_true(xpath.parse(  data, " $empty = ''",namespace ))
end

function test_unaryexpr(  )
  -- FIXME
  -- assert_equal(xpath.parse( data, " -4 ",namespace ), -4)
  -- assert_equal(xpath.parse( data, " +4 ",namespace ), 4)
  assert_equal(xpath.parse( data, " 4 ",namespace ), 4)
  assert_equal(xpath.parse( data, " 5 - 1 - 3 ",namespace ), 1)
end

function test_arg_function( )
  assert_equal(xpath.parse( data, " sd:groupheight('foo') ",namespace ),'foo')
end

-- function test_normalize_space(  )
--   assert_equal(xpath.normalize_space(" abc "),"abc")
-- end

function test_parse_arithmetic(  )
  assert_equal(xpath.parse( data, " 5"                         , namespace ), 5)
  assert_equal(xpath.parse( data, " 3.4 "                      , namespace ), 3.4)
  assert_equal(xpath.parse( data, " 'string' "                 , namespace ), "string")
  assert_equal(xpath.parse( data, " 5 * 6"                     , namespace ), 30)
  assert_equal(xpath.parse( data, " 9 * 4 div 6"               , namespace ), 6)
  assert_equal(xpath.parse( data, " 5 mod 2 "                  , namespace ), 1)
  assert_equal(xpath.parse( data, " 4 mod 2 "                  , namespace ), 0)
  assert_equal(xpath.parse( data, " sd:number-of-columns() mod 2 ", namespace ), 0)
  assert_equal(xpath.parse( data, " 6 + 5"                     , namespace ), 11)
  assert_equal(xpath.parse( data, " 6 - 5"                     , namespace ), 1)
  assert_equal(xpath.parse( data, " 6 + 5 + 3"                 , namespace ), 14)
  assert_equal(xpath.parse( data, " 10 - 10 - 5 "              , namespace ), -5)
  assert_equal(xpath.parse( data, " 6 + 4 * 2"                 , namespace ), 14)
  assert_equal(xpath.parse( data, " 6 + 4  div 2"              , namespace ), 8)
  assert_equal(xpath.parse( data, " ( 6 + 4 )"                 , namespace ), 10)
  assert_equal(xpath.parse( data, " ( 6 + 4 ) * 2"             , namespace ), 20)
  assert_equal(xpath.parse( data, " $column + 2"               , namespace ), 4)
  assert_equal(xpath.parse( data, " 1 - $counter"              , namespace ), 0)
  assert_equal(xpath.parse( data, " 3.4 * 2"                   , namespace ), 6.8)
  assert_equal(xpath.parse( data, "3.4 * $column"              , namespace ), 6.8)
  assert_equal(xpath.parse( data, " $column * 3.4"             , namespace ), 6.8)
end

function test_parse_string(  )
  assert_equal(xpath.parse( data, " 'ba\"r' ",namespace  ),"ba\"r")
end

-- function test_parse_node()
--   local first_sub = data[2]
--   local second_sub = data[4]
--   assert_equal(xpath.parse( first_sub, " . + 2", namespace  ), 125)
--   assert_equal(xpath.parse( data, " . "        , namespace  ), { data })
--   assert_equal(xpath.parse( data," sub "       , namespace  ),{first_sub,second_sub})
--   assert_equal(xpath.parse( data, " @a "       , namespace  ), "1")
-- end

function test_parse_functions()
  assert_equal(xpath.textvalue(xpath.parse( data, " sd:number-of-columns( 'area' ) "  ),namespace), '10')
  assert_equal(xpath.textvalue(xpath.parse( data, " sd:number-of-columns() - sd:number-of-columns() < 4"  ),namespace), true)
  assert_equal(xpath.textvalue(xpath.parse( data, " sd:number-of-columns() - sd:number-of-columns() - 5 = -5"  ),namespace), true)
end

function test_boolean(  )
  assert_equal(xpath.parse(data , " 3 < 6 "       ,namespace ),true)
  assert_equal(xpath.parse(data , " 6 < 3 "       ,namespace ),false)
  assert_equal(xpath.parse(data , " 3 < 3 "       ,namespace ),false)
  assert_equal(xpath.parse(data , " 3 <= 3 "      ,namespace ),true)
  assert_equal(xpath.parse(data , " 3 = 3 "       ,namespace ),true)
  assert_equal(xpath.parse(data , " 3 != 3 "      ,namespace ),false)
  assert_equal(xpath.parse(data , " 4 != 3 "      ,namespace ),true)
  assert_equal(xpath.parse(data , " 3 > 6 "       ,namespace ),false)
  assert_equal(xpath.parse(data , " 6 > 3 "       ,namespace ),true)
  assert_true(xpath.parse(data , " 'a' != '' "    ,namespace ))
  assert_equal(xpath.parse(data , " $column > 3 " ,namespace ),false)
  assert_equal(xpath.parse(data , " $counter = 1 ",namespace ),true)
  assert_true(xpath.parse( data , " sd:true() "   ,namespace ))
  assert_false(xpath.parse(data , " sd:false() "  ,namespace ))
end
