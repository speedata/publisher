-- Image loading, dimensions and shape support.
--
--  images.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

file_start("images.lua")

---@class images_module
local M = {}

---@class ImageInfo
---@field img table LuaTeX `img.scan` result with `xsize`, `ysize`, `transform` etc.
---@field allocate? table Optional 2D occupancy matrix (`mt[y][x] = 0|1`) plus `max_x`/`max_y`.

-- Per-process image cache, keyed by "<filename><page><box>"
---@type table<string, ImageInfo>
local images = {}

---@alias ImageDimAxis "width"|"height"

-- Resolves a length expression for an image dimension. Numeric values are
-- treated as grid units (multiplied by current grid width/height); strings
-- with explicit units (`"5mm"`) are converted via `tex.sp`. The literal
-- `"100%"` maps to the data-XML variable `__maxwidth` (width axis only).
---@param dataxml table Data XML root (used for variable lookup).
---@param len string|number|nil
---@param width_or_height ImageDimAxis
---@return integer? sp Length in scaled points, or `nil` for `nil`/`"auto"`.
function M.set_image_length(dataxml, len, width_or_height)
    if len == nil or len == "auto" then
        return nil
    elseif len == "100%" and width_or_height == "width" then
        if publisher.newxpath then
            return dataxml.vars["__maxwidth"]
        else
            return xpath.get_variable("__maxwidth")
        end
    elseif tonumber(len) then
        if width_or_height == "width" then
            return publisher.current_grid:width_sp(len)
        else
            return len * publisher.current_grid.gridheight
        end
    else
        return tex.sp(len)
    end
end

-- Computes the final width/height for an image given min/max constraints.
-- Implements the CSS 2.1 algorithm at
-- https://www.w3.org/TR/CSS2/visudet.html#min-max-widths. When `stretch`
-- is true and both maxima are finite, the image grows uniformly to fit
-- within (maxwidth, maxheight).
---@param image { xsize: integer, ysize: integer, width: integer, height: integer }
---@param width integer Initial width in sp.
---@param height integer Initial height in sp.
---@param minwidth integer
---@param minheight integer
---@param maxwidth integer
---@param maxheight integer
---@param stretch boolean? Grow up to (maxwidth, maxheight) if needed.
---@return integer width
---@return integer height
function M.calculate_image_width_height( image, width, height, minwidth, minheight, maxwidth, maxheight, stretch )
    -- See https://www.w3.org/TR/CSS2/visudet.html#min-max-widths
    if stretch and maxheight < publisher.maxdimen and maxwidth < publisher.maxdimen then
        local stretchamount = math.min(maxwidth / image.xsize , maxheight / image.ysize )
        if stretchamount > 1 then
            return image.xsize * stretchamount, image.ysize * stretchamount
        end
    end

    if width < minwidth and height > maxheight then
        width = minwidth
        height = maxheight
    elseif width > maxwidth and height < minheight then
        width = maxwidth
        height = minheight
    elseif width > maxwidth and height > maxheight and maxwidth / width <= maxheight / height then
        height = math.max(minheight, maxwidth * height/width)
        width = maxwidth
    elseif width > maxwidth and height > maxheight and maxwidth / width > maxheight / height then
        width = math.max(minwidth, maxheight * width / height)
        height = maxheight
    elseif width < minwidth and height < minheight and minwidth / width <= minheight / height then
        width = math.min(maxwidth, minheight * width / height)
        height = minheight
    elseif width < minwidth and height < minheight and minwidth / width > minheight / height then
        width = minwidth
        height = math.min(maxheight, minwidth * height / width)
    elseif width > maxwidth then
        height = math.max(maxwidth * height / width, minheight)
        width = maxwidth
    elseif width < minwidth then
        height = math.min(minwidth * height / width, maxheight)
        width = minwidth
    elseif height > maxheight then
        width = math.max(maxheight * width / height, minwidth)
        height = maxheight
    elseif height < minheight then
        width = math.min(minheight * width / height, maxwidth)
        height = minheight
    end

    -- If only one of height or width was given, adjust the other to keep aspect ratio
    if height == image.height then
        if width ~= image.width then
            height = height * width / image.width
        end
    elseif width == image.width then
        if height ~= image.height then
            width = width *  height / image.height
        end
    end
    return width, height
end

-- Reloads an image at a different target size. Honors the user's image
-- handler configuration (`options.extensionhandler`) and the matching
-- `publisher.resizehandler` to support external converters.
---@param filename string
---@param typ string Image type passed through to `splib.reloadimage`.
---@param width integer Target width in sp.
---@param height integer Target height in sp.
---@return any image_info Result from `splib.reloadimage`.
function M.reload_image(filename, typ, width, height)
    main.log("info","Reload image","width",tostring(width),"height",tostring(height),"filename",filename)
    local filename_extension = publisher.get_extension(filename)
    local handlername_for_extension
    local opts = publisher.options
    if opts.extensionhandler and opts.extensionhandler ~= "" then
        for _,v in ipairs(string.explode(opts.extensionhandler,";")) do
            local _,_,ext,handler = string.find(v,"^(.*):(.*)$")
            if ext == filename_extension then
                handlername_for_extension = handler
                break
            end
        end
    end
    local rh = publisher.resizehandler[handlername_for_extension or "*"]
    return splib.reloadimage({ filename = filename, imagetype = typ, width = width, height = height, resizehandler = rh })
end

-- Backwards-compatible alias for `imageinfo`.
---@param filename string
---@param page integer?
---@param box string?
---@param fallback string?
---@param imageshape boolean?
---@return ImageInfo
function M.new_image(filename, page, box, fallback, imageshape)
    return M.imageinfo(filename, page, box, fallback, imageshape)
end

-- Verifies the actual content of an image file and converts SVG to PDF on
-- the fly via `splib.convert_svg_image`. Returns the path to use for
-- subsequent `img.scan` calls.
---@param filename string
---@return string? localfilename `nil` when the file cannot be opened.
function M.validateimagetype(filename)
    local localfilename = kpse.find_file(filename)
    local f, errmsg = io.open(localfilename)
    if not f then
        err(errmsg)
        return nil
    end
    local whatever = f:read(5)
    if string.match(whatever, "<svg") then
        localfilename = splib.convert_svg_image(localfilename)
    end
    f:close()
    return localfilename
end

-- Picks the file name to use when the requested image is missing. Returns
-- `filename` if it exists, the built-in `"filenotfound.pdf"` otherwise.
---@param filename string? User-provided fallback name.
---@param missingfilename string? The original missing image (for logging).
---@return string
function M.get_fallback_image_name( filename, missingfilename )
    if filename then
        main.log("info","Using fallback","fallback",filename or "(filename)", "requested",missingfilename or "(empty)")
        if not kpse.find_file(filename) then
            err("fallback image %q not found",filename or "<filename>")
            return "filenotfound.pdf"
        end
        return filename
    else
        return "filenotfound.pdf"
    end
end

---@alias ImageBox "none"|"media"|"crop"|"bleed"|"trim"|"art"

-- Loads (and caches) an image. Looks for an accompanying `<file>.xml` shape
-- description if `imageshape` is true; loads it as a 2D occupancy matrix
-- so callers can fit text into the image's negative space.
---@param filename string?
---@param page integer? PDF page to load (defaults to `1`).
---@param box ImageBox? PDF box to use (defaults to `"crop"`).
---@param fallback string? File name to use if `filename` is missing.
---@param imageshape boolean? Load shape XML if present.
---@return ImageInfo info Cached entry.
function M.imageinfo( filename, page, box, fallback, imageshape )
    page = page or 1
    box = box or "crop"
    if not filename then
        err("No filename given for image")
        filename = M.get_fallback_image_name(fallback)
    end
    if type(filename) ~= "string" then
        err("something is wrong with the filename for the image, not a string")
        filename = M.get_fallback_image_name(fallback)
    end

    local new_name = filename .. tostring(page) .. tostring(box)

    if images[new_name] then
        return images[new_name]
    end
    main.log("info","Searching for image","filename",tostring(filename))
    if not kpse.find_file(filename) then
        if publisher.options.imagenotfounderror then
            main.log("error","Image not found","filename", filename or "???", publisher.lineinfo())
        else
            main.log("warn","Image not found","filename", filename or "???", publisher.lineinfo())
        end
        filename = M.get_fallback_image_name(fallback, filename)
        page = 1
    end
    main.log("info","Load image","filename",tostring(filename))

    local mt
    if imageshape and not string.match(filename, "^https?://") then
        local xmlfilename = string.gsub(filename, "(%..*)$", "") .. ".xml"

        if kpse.find_file(xmlfilename) then
            local xmltab, msg = publisher.load_xml(xmlfilename, "Imageinfo")
            if not xmltab then
                err(msg)
            else
                if publisher.newxpath then
                    xmltab = xmltab[1]
                end
                mt = {}
                local segments = {}
                local cells_x, cells_y
                for _, v in ipairs(xmltab) do
                    if v[".__local_name"] == "cells_x" then
                        cells_x = tonumber(v[1])
                    elseif v[".__local_name"] == "cells_y" then
                        cells_y = tonumber(v[1])
                    elseif v[".__local_name"] == "segment" then
                        if publisher.newxpath then
                            local attrs = v[".__attributes"]
                            segments[#segments + 1] = {tonumber(attrs.x1), tonumber(attrs.y1), tonumber(attrs.x2), tonumber(attrs.y2)}
                        else
                            segments[#segments + 1] = {tonumber(v.x1), tonumber(v.y1), tonumber(v.x2), tonumber(v.y2)}
                        end
                    end
                end
                mt.max_x = cells_x
                mt.max_y = cells_y
                for i = 1, cells_y do
                    mt[i] = {}
                    for j = 1, cells_x do
                        mt[i][j] = 0
                    end
                end
                for _, v in ipairs(segments) do
                    for x = v[1], v[3] do
                        for y = v[2], v[4] do
                            mt[y][x] = 1
                        end
                    end
                end
            end
        end
    end

    if not images[new_name] then
        if string.match(filename, ".svg$") then
            filename = splib.convert_svg_image(filename)
            if filename == nil or filename == "" then
                filename = "filenotfound.pdf"
            else
                log("Using converted file %q instead", filename)
            end
        end
        filename = M.validateimagetype(filename)
        local image_info = img.scan{ filename = filename, pagebox = box, page = page, keepopen = true }
        if image_info.orientation == 0 then
            -- good, no transformation
        elseif image_info.orientation == 1 then
            image_info.transform = 0
        elseif image_info.orientation == 2 then
            image_info.transform = 4
        elseif image_info.orientation == 3 then
            image_info.transform = 2
        elseif image_info.orientation == 4 then
            image_info.transform = 6
        elseif image_info.orientation == 5 then
            image_info.transform = 5
        elseif image_info.orientation == 6 then
            image_info.transform = 3
        elseif image_info.orientation == 7 then
            image_info.transform = 7
        elseif image_info.orientation == 8 then
            image_info.transform = 1
        end
        images[new_name] = { img = image_info, allocate = mt }
    end
    return images[new_name]
end

file_end("images.lua")

return M
