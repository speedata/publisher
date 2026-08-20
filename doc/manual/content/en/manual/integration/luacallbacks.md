---
title: "Lua callbacks"
weight: 66
type: docs
---

Some parts of the publishing run can be customized with Lua functions: the file lookup and the conversion of images with external programs.
For this purpose a Lua file is given with the configuration setting `luafile` (or on the command line with `--luafile`), for example:

```
luafile = hooks.lua
```

The file is loaded at the beginning of the publishing run, before the layout and data files are opened.
It registers functions for fixed callback names with `register_callback()`:

```lua
register_callback("lookup_file", function(name)
    -- ...
end)
```

The setting is only read from the configuration file and the command line on purpose.
It cannot be set in the layout file, so a layout can never inject code into the publishing process (think of the server mode).

Available since version 5.9.2. The callbacks replace the configuration settings `pathrewrite`, `imagehandler` and `resizehandler` in the long run; these settings still work as before and are used whenever a callback is not registered or returns `nil`.

## The environment of the callback file

The callback file does not see the publisher internals. It runs in a restricted environment that provides only the official API:

`register_callback(name, fn)`
: Register the function `fn` for one of the callback names described below.

`log(level, message, key, value, ...)`
: Write a message to the protocol file. The level is one of `debug`, `info`, `warn` or `error`.

`api.version`
: The version of the callback API. Currently `1`.

Standard library
: `string`, `table`, `math`, `tonumber`, `tostring`, `error`, `assert`, `pcall`, `pairs`, `ipairs`, `next`, `type`, `select`, `io.open`, `io.lines` and `os.getenv`.

Only plain values (strings, numbers and tables of those) cross the boundary between the publisher and the callbacks.
This keeps the callback file independent of the publisher internals.

## lookup_file

The callback gets the name of every requested file (images, fonts, layout and data XML, URLs) before the built-in file lookup runs.
It can return a new name, or `nil` to leave the name unchanged.
The regular lookup then runs with the resulting name.

```lua
register_callback("lookup_file", function(name)
    if string.match(name, "^D:\\MEDIA\\") then
        name = string.gsub(name, "^D:\\MEDIA\\", "images/")
        return string.gsub(name, "\\", "/")
    end
end)
```

This is a more powerful replacement for the `pathrewrite` setting: the callback can use patterns, case insensitive matching or a lookup table read from an external file.
Since the callback fires for every file lookup (also for fonts and internal files), it should return quickly.
The result for each name is cached during the run, so the callback must always return the same result for the same name.

## image_handler

The callback decides how an image file is converted to a format that the publisher can include (PDF, PNG or JPEG).
It gets a table with these entries:

`input`
: The full path of the image file.

`extension`
: The lowercased file name extension, for example `tif`. Empty for embedded image contents.

`imagetype`
: Only for embedded image contents (`<Image>` with child elements): the value of the `imagetype` attribute.

`outputbase`
: A path in the image cache (without extension) that is reserved for the output file of this conversion.

The callback returns one of the following:

* `nil`: the image is not handled by the callback. The `imagehandler` configuration and the built-in handlers apply as before.
* A table with `command` and `output`: the publisher runs the command (a list with the program and one entry per argument) and includes the file `output`.
* A table with only `output`: the file is included as it is, without running a program.

```lua
register_callback("image_handler", function(job)
    if job.extension == "tif" then
        local out = job.outputbase .. ".pdf"
        return {
            command = { "magick", job.input, out },
            output = out,
        }
    end
end)
```

Since the command is a list, no quoting or escaping is needed, even for file names with spaces.
The output file is kept in the image cache: when it already exists, the command is not run again.
The cache name in `outputbase` contains a hash over the input path and the callback file, so a changed callback file automatically invalidates the cache.
When the command fails, its complete output is written to the protocol file.

## resize_handler

Professional feature: when the `dpi` attribute of `<PDFOptions>` is set, images with a higher resolution are downsampled.
The `resize_handler` callback can take over this conversion.
It gets the same table as `image_handler` with these additional entries:

`width`, `height`
: The requested size of the output image in pixels.

`imagetype`
: The type of the image, `png` or `jpg`.

The return value works exactly like the one of `image_handler`:

```lua
register_callback("resize_handler", function(job)
    local out = job.outputbase .. ".png"
    return {
        command = { "magick", job.input, "-resize", job.width .. "x" .. job.height, out },
        output = out,
    }
end)
```
