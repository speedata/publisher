module(..., package.seeall)

header = [[<!DOCTYPE html>

<html>
<head>
  <title>%title%</title>
  <meta http-equiv="content-type" content="text/html; charset=UTF-8">
  <link rel="stylesheet" media="all" href="locco.css" />
</head>
<body>
  <div id="container">
    <div id="background"></div>
    %jump%
    <table>
      <thead>
        <tr>
          <th class="docs">
            <span class="h1">%title%</span>
          </th>
          <th class="code">
          </th>
        </tr>
      </thead>
      <tbody>
]]

jump_start = [[
<div id="jump_to">
  Jump To &hellip;
  <div id="jump_wrapper">
  <div id="jump_page">
]]

jump = [[
  <a class="source" href="%jump_html%">%jump_lua%</a>
]]

jump_end = [[
    </div>
  </div>
</div>
]]

table_entry = [[
<tr id="section-%index%">
<td class="docs">
  <div class="pilwrap">
    <a class="pilcrow" href="#section-%index%">&#182;</a>
  </div>
  %docs_html%
</td>
<td class="code">
  %code_html%
</td>
</tr>]]

footer = [[</tbody>
    </table>
  </div>
</body>
</html>]]
