module(...,package.seeall)

xpath = do_luafile("xpath.lua")
luxor = do_luafile("luxor.lua")

xpath.set_variable("column",2)
xpath.set_variable("counter",1)
xpath.set_variable("textvar","yes")
xpath.set_variable("empty","")
xpath.set_variable("istrue",true)
xpath.set_variable("isfalse",false)
xpath.set_variable("foo-bar",'foobar')

local data_src=[[
<?xml version="1.0" encoding="UTF-8"?>
 <?xml-foo ?>
<root one="1" foo='no' empty="" quotationmarks="&#34;text&#34;">
 <?xml-foo ?>
 <sub foo="baz">123</sub>
 <sub foo="bar">contents</sub>
</root>
]]

local mixed_elements_src=[[<root>
 <one><subone a="b" /><subone /></one>
 <two><subtwo /><anoterhsubtwo /></two>
</root>]]

local with_underscore_src=[[<root>
 <foo_bar>Hello world</foo_bar>
</root>]]

local with_dash_src=[[<foo att="Hello world">xx<bar-bar att="xx"></bar-bar></foo>]]


local data = luxor.parse_xml(data_src)
local with_underscore = luxor.parse_xml(with_underscore_src)
local with_dash = luxor.parse_xml(with_dash_src)
local mixed_elements = luxor.parse_xml(mixed_elements_src)
local namespace = { sd = "foo" }

function number_of_datasets(self,arg)
    local count = 0
    for i=1,#arg do
        if type(arg[i]) == 'table' and arg[i][".__type"] == "element" then count = count + 1 end
    end
    return count
end

--- Insert 1000's separator and comma separator
local function format_number(dataxml,arg)
  local num, thousandssep,commasep = arg[1], arg[2], arg[3]
  local sign,digits,commadigits = string.match(tostring(num),"([%-%+]?)(%d*)%.?(%d*)")
  local first_digits = math.fmod(#digits,3)
  local ret = {}
  if first_digits > 0 then
    ret[1] = string.sub(digits,0,first_digits)
  end
  for i=1, ( #digits - first_digits) / 3 do
    ret[#ret + 1] = string.sub(digits,first_digits + ( i - 1) * 3 + 1 ,first_digits + i * 3 )
  end
  ret = table.concat(ret, thousandssep)
  if commadigits and #commadigits > 0 then
    return  sign .. ret .. commasep .. commadigits
  else
    return sign .. ret
  end
end


local function format_string( dataxml,arg )
  return string.format(arg[2],arg[1])
end

xpath.register_function("foo","verbose",function(dataxml,arg)  printtable("verbose",arg) return true end)
xpath.register_function("foo","even",function(dataxml,x) return math.fmod(x[1],2) == 0 end)
xpath.register_function("foo","return-ten",function(dataxml) return 10 end)
xpath.register_function("foo","number-of-datasets",number_of_datasets)
xpath.register_function("foo","format-string",format_string)
xpath.register_function("foo","format-number",format_number)

function test_foo()
end

function test_ifthenelse()
  assert_true(secondoftwo(xpath.parse_raw(data,  " if ( 1 = 1 ) then true() else false()",namespace))[1] )
  assert_false(secondoftwo(xpath.parse_raw(data, " if ( 1 = 2 ) then true() else false()",namespace))[1] )
  assert_equal(secondoftwo(xpath.parse_raw(data, " if ( true() ) then 1 else 2",namespace))[1],1 )
  assert_equal(secondoftwo(xpath.parse_raw(data, " if ( false() ) then 1 else 2",namespace))[1],2 )
  assert_equal(secondoftwo(xpath.parse_raw(data, " if ( false() ) then 'a' else 'b'",namespace))[1],"b")
  assert_equal(secondoftwo(xpath.parse_raw(data, " if ( true() ) then 'a' else 'b'",namespace))[1],"a")
end

function test_idiv()
  assert_equal(secondoftwo(xpath.parse_raw( data, " 10 idiv 3 ",namespace ))[1], 3)
  assert_equal(secondoftwo(xpath.parse_raw( data, " 3 idiv -2 ",namespace ))[1], -1)
  assert_equal(secondoftwo(xpath.parse_raw( data, " -3 idiv 2 ",namespace ))[1], -1)
  assert_equal(secondoftwo(xpath.parse_raw( data, " -3 idiv -2 ",namespace ))[1], 1)
  assert_equal(secondoftwo(xpath.parse_raw( data, " 9.0 idiv 3 ",namespace ))[1], 3)
  assert_equal(secondoftwo(xpath.parse_raw( data, " -3.5 idiv 3 ",namespace ))[1], -1)
  assert_equal(secondoftwo(xpath.parse_raw( data, " 3.0 idiv 4 ",namespace ))[1], 0)
end

function test_xpathfunctions()
    assert_equal(secondoftwo(xpath.parse_raw( data, " normalize-space('  foo bar baz     ') ",namespace ))[1], "foo bar baz")
    assert_equal(secondoftwo(xpath.parse_raw( data, " upper-case('äöüaou') ",namespace ))[1], "ÄÖÜAOU")
    assert_equal(secondoftwo(xpath.parse_raw( data, " max(1,2,3) ",namespace ))[1], 3)
    assert_equal(secondoftwo(xpath.parse_raw( data, " min(1,2,3) ",namespace ))[1], 1)
    assert_equal(secondoftwo(xpath.parse_raw( data, " last() ",namespace ))[1], 1)
end

function test_castable()
    assert_true(secondoftwo(xpath.parse_raw(data," 123 castable as xs:double",namespace))[1])
    assert_true(secondoftwo(xpath.parse_raw(data," '123' castable as xs:double",namespace))[1])
    assert_true(secondoftwo(xpath.parse_raw(data," 123 castable as xs:string",namespace))[1])
    assert_false(secondoftwo(xpath.parse_raw(data," 'abc' castable as xs:double",namespace))[1])
end

function test_numdatasets()
    assert_equal(xpath.parse( data, " sd:number-of-datasets(.) ",namespace ), 1)
    assert_equal(#xpath.parse( data, " sub ",namespace),2)
    assert_equal(#xpath.parse( data, " sub,sub,sub ",namespace),6)
    assert_equal(secondoftwo(xpath.parse_raw( mixed_elements, " sd:number-of-datasets(*)",namespace ))[1], 2)
    assert_equal(secondoftwo(xpath.parse_raw( mixed_elements, " sd:number-of-datasets(one)",namespace ))[1], 1)
    assert_equal(secondoftwo(xpath.parse_raw( mixed_elements, " count(*)",namespace ))[1], 2)
    assert_equal(secondoftwo(xpath.parse_raw( mixed_elements, " count(one/subone)",namespace ))[1], 2)
    assert_equal(secondoftwo(xpath.parse_raw( mixed_elements, " count(*[1])",namespace ))[1], 1)
    assert_equal(secondoftwo(xpath.parse_raw( mixed_elements, " count(two/*)",namespace ))[1], 2)
    assert_equal(secondoftwo(xpath.parse_raw( mixed_elements, " count(nonexist)",namespace ))[1], 0)
end


function test_variable()
    assert_equal(xpath.get_variable("column"),2)
    assert_false(firstoftwo(xpath.parse_raw(data,"$doesnotexist",namespace)))
    assert_equal(secondoftwo(xpath.parse_raw(data,"$foo-bar",namespace))[1], 'foobar')
    assert_equal(secondoftwo(xpath.parse_raw(data,"$abcäüödef",namespace)), 'Variable "abcäüödef" undefined')
end

function test_andorexpr( )
    assert_true( secondoftwo(xpath.parse_raw(data, "@one=1 and @foo='no'",namespace))[1])
    assert_true( secondoftwo(xpath.parse_raw( data, " 2 > 4 or 3 > 5 or 6 > 2",namespace ))[1] )
    assert_true(xpath.parse( data, " 2 > 4 or 3 > 5 or 6 > 2",namespace ))
    assert_true(xpath.parse( data, " true() or false() ",namespace ))
    assert_true(xpath.parse( data, " true() and true() ",namespace ))
    assert_false(xpath.parse( data, " true() and false() ",namespace ))
    assert_false(xpath.parse( data, " false() or false() ",namespace ))
    assert_true(xpath.parse(data,"'a' = 'a'"))
    assert_true(xpath.parse( data, " 'a' = 'a' and 'b' = 'b' ",namespace ))
    assert_false(xpath.parse( data, " 6 < 4 and 7 > 5 ",namespace ))
    assert_true(xpath.parse( data, " 2 < 4 and 7 > 5 ",namespace ))
end

function test_parse_string(  )
  assert_equal(xpath.parse( data, " 'ba\"r' ",namespace  ),"ba\"r")
end


function test_parse_functions()
    assert_equal(xpath.textvalue(xpath.parse( data, " sd:return-ten( 'area' ) "  ,namespace)), '10')
    -- why true and not "true"?
    assert_equal(xpath.textvalue(xpath.parse( data, " sd:return-ten() - sd:return-ten() < 4" ,namespace )), true)
    assert_equal(xpath.textvalue(xpath.parse( data, " sd:return-ten() - sd:return-ten() - 5" ,namespace )), '-5')

    -- raw:
    assert_equal(xpath.textvalue_raw(xpath.parse_raw( data, " sd:return-ten( 'area' ) "  ,namespace)), '10')
    -- why true and not "true"?
    assert_equal(xpath.textvalue_raw(xpath.parse_raw( data, " sd:return-ten() - sd:return-ten() < 4" ,namespace )), true)
    assert_equal(xpath.textvalue_raw(xpath.parse_raw( data, " sd:return-ten() - sd:return-ten() - 5" ,namespace )), '-5')
    assert_true(xpath.parse(data,"sd:even(sd:return-ten())",namespace ))
    assert_equal(secondoftwo(xpath.parse_raw(data,"sd:format-number(sd:format-string(1234.567, '%.2f'), '.', ',')",namespace))[1],"1.234,57")
    local data = luxor.parse_xml([[<A><B>foo</B></A>]])
    assert_true(secondoftwo(xpath.parse_raw(data," string(B) = 'foo' or string(B) = 'bar' ",namespace))[1])
    assert_true(secondoftwo(xpath.parse_raw(data," string( B ) = 'foo' or string( B ) = 'bar' ",namespace))[1])
end


function test_unaryexpr(  )
  assert_equal(xpath.parse( data, " -4 ",namespace ), -4)
  assert_equal(xpath.parse( data, " +4 ",namespace ), 4)
  assert_equal(xpath.parse( data, " 4 ",namespace ), 4)
  assert_equal(xpath.parse( data, " 5 - 1 - 3 ",namespace ), 1)
end


function test_stringcomparison()
  assert_equal(xpath.parse( data, " $textvar ",namespace ), 'yes')
  assert_false(xpath.parse( data, " $textvar = 'no'",namespace ))
  assert_true(xpath.parse(  data, " $empty = ''",namespace ))
end


function test_paren()
    assert_equal(xpath.parse( data, " ( 6 + 4 )"                 , namespace ), 10)
    assert_equal(xpath.parse( data, " ( 6 + 4 ) * 2"             , namespace ), 20)
end

function test_comparison(  )
    assert_true(xpath.parse(data, " 3 < 6 " ))
    assert_true(xpath.parse(data, " 6 > 3 " ))
    assert_true(xpath.parse(data, " 3 <= 3 " ))
    assert_true(xpath.parse(data, " 3 = 3 " ))
    assert_true(xpath.parse(data, " 4 != 3 " ))
    assert_false(xpath.parse(data , " $column > 3 "))
    assert_true(xpath.parse(data , " $counter = 1 "))
end

function test_parse_arithmetic(  )
  assert_equal(xpath.parse( data, " 5"                         , namespace ), 5)
  assert_equal(xpath.parse( data, " 3.4 "                      , namespace ), 3.4)
  assert_equal(xpath.parse( data, " 'string' "                 , namespace ), "string")
  assert_equal(xpath.parse( data, " 5 * 6"                     , namespace ), 30)
  assert_equal(secondoftwo(xpath.parse_raw( data," @one * 9.2" , namespace ))[1], 9.2)
  assert_equal(xpath.parse( data, " 5 mod 2 "                  , namespace ), 1)
  assert_equal(xpath.parse( data, " 4 mod 2 "                  , namespace ), 0)
  assert_equal(xpath.parse( data, " 9 * 4 div 6"               , namespace ), 6)
  assert_equal(xpath.parse( data, " sd:return-ten() mod 2 ", namespace ), 0)
  assert_equal(xpath.parse( data, " 6 + 5"                     , namespace ), 11)
  assert_equal(xpath.parse( data, " 6 - 5"                     , namespace ), 1)
  assert_equal(xpath.parse( data, " 6-5"                     , namespace ), 1)
  assert_equal(xpath.parse( data, " 6 + 5 + 3"                 , namespace ), 14)
  assert_equal(xpath.parse( data, " 10 - 10 - 5 "              , namespace ), -5)
  assert_equal(xpath.parse( data, " 4 * 2 + 6"                 , namespace ), 14)
  assert_equal(xpath.parse( data, " 6 + 4 * 2"                 , namespace ), 14)
  assert_equal(xpath.parse( data, " 6 + 4  div 2"              , namespace ), 8)
  assert_equal(xpath.parse( data, " $column + 2"               , namespace ), 4)
  assert_equal(xpath.parse( data, " 1 - $counter"              , namespace ), 0)
  assert_equal(xpath.parse( data, " 3.4 * 2"                   , namespace ), 6.8)
  assert_equal(xpath.parse( data, "3.4 * $column"              , namespace ), 6.8)
  assert_equal(xpath.parse( data, " $column * 3.4"             , namespace ), 6.8)
end

function test_num()
    assert_equal(xpath.parse(data, " -3.2 " ),-3.2)
    assert_equal(xpath.parse(data, " -3" ),-3)
end

function test_string()
    assert_equal(xpath.parse(data, "'aäßc'" ),'aäßc')
    assert_equal(xpath.parse(data, '"aäßc"' ),'aäßc')
    assert_equal(xpath.parse(data, "  'aäßc'  " ),'aäßc')
end

function test_multiple()
    assert_equal(xpath.parse(data, "3 , 3" ),{3,3})
end

function test_attribute()
    assert_equal(xpath.parse(data, "@one" ),'1')
    assert_equal(xpath.parse(data, "@quotationmarks" ),'"text"')
    assert_false(secondoftwo(xpath.parse_raw( data, "  @undefined='foo' ",namespace ))[1])
    assert_false(secondoftwo(xpath.parse_raw( data, "  @undefined='foo' ",namespace ))[1])
    assert_true(secondoftwo(xpath.parse_raw( data, "  @undefined != 'foo' ",namespace ))[1])
    assert_false(secondoftwo(xpath.parse_raw( data, "  @undefined != @undefined ",namespace ))[1])
    assert_false(secondoftwo(xpath.parse_raw( data, "  @undefined = @undefined ",namespace ))[1])
    assert_false(secondoftwo(xpath.parse_raw( data, "  @undefined >= @undefined ",namespace ))[1])
    assert_true(secondoftwo(xpath.parse_raw(data, " empty(@undefined) "))[1])
    assert_true(secondoftwo(xpath.parse_raw(data, " empty(@empty) "))[1])
end


function test_functions()
    -- unknown function should return an error
    assert_false(firstoftwo(xpath.parse_raw(data, " doesnotexist() ",namespace)))
    assert_true(xpath.parse( data , " true() "   ,namespace ))
    assert_false(xpath.parse(data , " false() "  ,namespace ))
    assert_true(xpath.parse(data , " sd:even($column) ",namespace ))
    assert_false(xpath.parse(data, " $isfalse = true() ",namespace))
    assert_equal(xpath.parse(data , " concat($column, 'abc' ) ",namespace ),"2abc")
    -- dashes:
    assert_equal(xpath.parse( data, " sd:return-ten() ", namespace ), 10)
end

function test_other()
  assert_equal(secondoftwo(xpath.parse_raw(with_underscore," string(foo_bar) ",namespace))[1], "Hello world")
  assert_equal(secondoftwo(xpath.parse_raw(with_dash," foo/bar-bar/@att ",namespace))[1], "xx")
  assert_false(secondoftwo(xpath.parse_raw(data,  " a = '*'",namespace))[1] )
  assert_false(secondoftwo(xpath.parse_raw(data,  " a = '+'",namespace))[1] )
end

