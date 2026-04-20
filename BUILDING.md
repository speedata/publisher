# Building the speedata Publisher from source

## Prerequisites

- Go 1.21 or later
- Lua 5.3 header files
- Standard build tools (make, gcc)
- Ruby with rake

On Debian/Ubuntu:

```sh
sudo apt install build-essential git rake golang liblua5.3-dev
```

## Build

```sh
git clone https://github.com/speedata/publisher.git
cd publisher
rake build
rake buildlib
```

If the Lua headers are not in `/usr/include/lua5.3`, set `CGO_CFLAGS`:

```sh
export CGO_CFLAGS="-I/usr/local/include/lua5.3"
```

### Windows

Set `CGO_LDFLAGS` to point to the LuaTeX binary directory:

```sh
set CGO_LDFLAGS=-llua53w64 -L/path/to/luatex/windows/amd64/default/
```

You may also need the [Microsoft Visual C++ runtime](https://support.microsoft.com/en-us/help/2977003/the-latest-supported-visual-c-downloads) (`VCRuntime140.dll`). The installation path must not contain non-ASCII characters.

### Cross-compiling

To compile for platforms other than your host (Linux/AMD64, Windows/AMD64, macOS/ARM), set a `CC_<platform>_<os>` variable pointing to the cross-compiler:

```sh
export CC_arm64_linux=/usr/bin/aarch64-linux-gnu-gcc
```

See also [this discussion](https://github.com/speedata/publisher/issues/607#issuecomment-2304523560).

## LuaTeX

The speedata Publisher requires a custom LuaTeX binary (`sdluatex`). Download it from <https://download.speedata.de/#extra> and place it in the `bin/` directory:

```sh
wget https://download.speedata.de/files/extra/luatex_115-win-mac-linux.zip
unzip luatex_115-win-mac-linux.zip
cp luatex/linux/sdluatex bin/
```

Verify with `bin/sdluatex --version`.

## Documentation

```sh
rake doc
```

## Running tests

```sh
rake qa
```
