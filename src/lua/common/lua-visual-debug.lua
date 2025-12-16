-- Copyright 2012-2023 Patrick Gundlach, patrick@gundla.ch Public repository:
-- https://github.com/pgundlach/lvdebug (issues/pull requests,...) Version: see
-- Makefile

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.


-- There are 65782 scaled points in a PDF point
-- Therefore we need to divide all TeX lengths by
-- this amount to get the PDF points.
local number_sp_in_a_pdf_point = tex.sp('1bp')


-- The idea is the following: at page shipout, all elements on a page are fixed.
-- TeX creates an intermediate data structure before putting that into the PDF
-- We can "intercept" that data structure and add pdf_literal (whatist) nodes,
-- that makes glues, kerns and other items visible by drawing a rule, rectangle
-- or other visual aids. This has no influence on typeset material, because
-- these pdf_literal instructions are only visible to the PDF file (PDF
-- renderer) and have no size themselves.

-- We recursively loop through the contents of boxes and look at the (linear)
-- list of items in that box. We start at the "shipout box".

-- The "algorithm" goes like this:
--
-- head = pointer_to_beginning_of_box_material
-- while head is not nil
--   if this_item_is_a_box
--     recurse_into_contents
--     draw a rectangle around the contents
--   elseif this_item_is_a_glue
--     draw a rule that has the length of that glue
--   elseif this_item_is_a_kern
--     draw a rectangle with width of that kern
--   ...
--   end
--   move pointer to the next item in the list
--   -- the pointer is "nil" if there is no next item
-- end

local HLIST = node.id("hlist")
local VLIST = node.id("vlist")
local RULE = node.id("rule")
local DIR  = node.id("dir")
local DISC = node.id("disc")
local GLUE = node.id("glue")
local KERN = node.id("kern")
local PENALTY = node.id("penalty")
local GLYPH = node.id("glyph")

local fmt = string.format
local floor = math.floor
local insert = table.insert
local insert_after = node.insert_after
local insert_before = node.insert_before

local running_glue_dimen = -2^30

local params = {
    hlist = {show = true, color = "0.5 G", width = 0.1},
    vlist = {show = true, color = "0.1 G", width = 0.1},
    rule = {show = true, color = "1 0 0 RG", width = 0.4},
    disc = {show = true, color = "0 0 1 RG", width = 0.3},
    glue = {show = true},
    kern = {show = true, negative_color = "1 0 0 rg", color = "1 1 0 rg", width = 1},
    penalty = {show = true},
    glyph = {show = false, color = "1 0 0 RG", width = 0.1, baseline = true},
    opacity = ""
}

local function math_round(num, idp)
  if idp and idp>0 then
    local mult = 10^idp
    return floor(num * mult + 0.5) / mult
  end
  return floor(num + 0.5)
end

local curdir = {}

local show_page_elements

local function show_page_elements(parent)
  local head = parent.list
  while head do
    local has_dir = false
    if head.dir == "TLT" then
      insert(curdir,"ltr")
      has_dir=true
    elseif head.dir == "TRT" then
      insert(curdir,"rtl") has_dir=true
    end
    if head.id == HLIST or head.id == VLIST then
      local boxtype = node.type(head.id)
      local rule_width = params[boxtype].width
      local wd = math_round(head.width                  / number_sp_in_a_pdf_point - rule_width     ,2)
      local ht = math_round((head.height + head.depth)  / number_sp_in_a_pdf_point - rule_width / 2 ,2)
      local dp = math_round(head.depth                  / number_sp_in_a_pdf_point - rule_width / 2 ,2)

      -- recurse into the contents of the box
      show_page_elements(head)
      if params[boxtype].show then
        local rectangle = node.new("whatsit","pdf_literal")
        local factor = 1
        if curdir[#curdir] == "rtl" then factor = -1 end
        if head.id == HLIST then -- hbox
          rectangle.data = fmt("q %s %s %g w %g %g %g %g re s Q", 
            params.opacity,params.hlist.color, rule_width, -factor*rule_width / 2, -dp, factor*wd, ht)
        else
          rectangle.data = fmt("q %s %s %g w %g %g %g %g re s Q", 
            params.opacity,params.vlist.color, rule_width, -factor*rule_width / 2, 0, factor*wd, -ht)
        end
        head.list = insert_before(head.list,head.list,rectangle)
      end

    elseif head.id == RULE and params.rule.show then
      local show_rule = node.new("whatsit","pdf_literal")
      if head.width == running_glue_dimen or head.height == running_glue_dimen or head.depth == running_glue_dimen then
        -- ignore for now -- these rules are stretchable
      else
        local dp = math_round( head.depth / number_sp_in_a_pdf_point  ,2)
        local ht = math_round( head.height / number_sp_in_a_pdf_point ,2)
        show_rule.data =  fmt("q %s %s %g w 0 %g m 0 %g l S Q",
          params.opacity,params.rule.color, params.rule.width, -dp, ht)
      end
      parent.list = insert_before(parent.list,head,show_rule)


    elseif head.id == DISC and params.disc.show then
      local hyphen_marker = node.new("whatsit","pdf_literal")
      hyphen_marker.data = fmt("q %s %s %g w 0 -1 m 0 0 l S Q",
        params.opacity,params.disc.color, params.disc.width)
      parent.list = insert_before(parent.list,head,hyphen_marker)

    elseif head.id == DIR then
      local mode = string.sub(head.dir,1,1)
      local texdir = string.sub(head.dir,2,4)
      local ldir
      if texdir == "TLT" then ldir = "ltr" else ldir = "rtl" end
      if mode == "+" then
          insert(curdir,ldir)
      elseif mode == "-" then
          local x = table.remove(curdir)
          if x ~= ldir then
              print(fmt("paragraph direction incorrect, found %s, expected %s",ldir,x))
          end
      end

    elseif head.id == GLUE and params.penalty.show then
      local head_spec = head.spec
      if not head_spec then
        head_spec = head
      end
      local wd = head_spec.width
      local color = "0.5 G"
      if parent.glue_sign == 1 and parent.glue_order == head_spec.stretch_order then
        wd = wd + parent.glue_set * head_spec.stretch
        color = "0 0 1 RG"
      elseif parent.glue_sign == 2 and parent.glue_order == head_spec.shrink_order then
        wd = wd - parent.glue_set * head_spec.shrink
        color = "1 0 1 RG"
      end
      local pdfstring = node.new("whatsit","pdf_literal")
      local wd_bp = math_round(wd / number_sp_in_a_pdf_point,2)
      if curdir[#curdir] == "rtl" then wd_bp = wd_bp * -1 end

      if parent.id == HLIST then
        pdfstring.data = fmt("q %s [0.2] 0 d 0.5 w 0 0 m %g 0 l S Q", color, wd_bp)
      else -- vlist
        pdfstring.data = fmt("q 0.1 G 0.1 w -0.5 0 m 0.5 0 l -0.5 %g m 0.5 %g l S [0.2] 0 d  0.5 w 0.25 0  m 0.25 %g l S Q",-wd_bp,-wd_bp,-wd_bp)
      end
      parent.list = insert_before(parent.list,head,pdfstring)

    elseif head.id == KERN and params.kern.show then
      local rectangle = node.new("whatsit","pdf_literal")
      local color = head.kern < 0 and params.kern.negative_color
        or params.kern.color
      local k = math_round(head.kern / number_sp_in_a_pdf_point,2)
      if parent.id == HLIST then
        rectangle.data = fmt("q %s %s 0 w 0 0 %g %g re B Q",
          params.opacity, color, k, params.kern.width)
      else
        rectangle.data = fmt("q %s %s 0 w 0 0 %g %g re B Q",
          params.opacity, color, params.kern.width, -k)
      end
      parent.list = insert_before(parent.list,head,rectangle)


    elseif head.id == PENALTY and params.penalty.show then
      local color = "1 g"
      local rectangle = node.new("whatsit","pdf_literal")
      if head.penalty < 10000 then
        color = fmt("%d g", 1 - floor(head.penalty / 10000))
      end
      rectangle.data = fmt("q %s 0 w 0 0 1 1 re B Q",color)
      parent.list = insert_before(parent.list,head,rectangle)
    
    elseif head.id == GLYPH and params.glyph.show then
      local rule_width = params.glyph.width
      local wd = -math_round(head.width                 / number_sp_in_a_pdf_point - rule_width     ,2)
      local ht = math_round((head.height + head.depth)  / number_sp_in_a_pdf_point - rule_width / 2 ,2)
      local dp = math_round(head.depth                  / number_sp_in_a_pdf_point - rule_width / 2 ,2)
      local rectangle = node.new("whatsit", "pdf_literal")
      local factor = 1
      if curdir[#curdir] == "rtl" then factor = -1 end
      local baseline = ""
      if head.depth ~= 0 and params.glyph.baseline then
        baseline = fmt("%g %g m %g %g l",
          0, -rule_width / 2, factor*(wd-rule_width), -rule_width / 2)
      end      
      rectangle.data = fmt("q %s %s %g w %s %g %g %g %g re s Q",
        params.opacity, params.glyph.color, rule_width, baseline, -factor*rule_width / 2, -dp, factor*wd, ht)
      parent.list, head = insert_after(parent.list,head,rectangle)
    end
    
    if has_dir then
      table.remove(curdir)
    end
    head = head.next
  end
  return true
end


return {
  show_page_elements = show_page_elements,
  params = params
}