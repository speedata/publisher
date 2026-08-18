---
title: "Compatibility with older versions"
weight: 230
type: docs
---


The development of the speedata Publisher has one big "mantra": existing setups must work with newer versions of the speedata Publisher without change. So you can always upgrade to the latest version without having to fear that you need to change your layout file.

New features are introduced via new XML tags or attributes.
Existing layout files simply ignore them and continue to work.

## Removed in version 6.0

Since version 5, the XPath parser `lxpath` and the font loader `harfbuzz` are the defaults.
The older variants (`luxor` and `fontforge`) have been removed in version 6.0.
Selecting them (via the `xpath` or `fontloader` key in the [configuration file]({{< relref "configuration" >}}), the attribute `mode="fontforge"` on `<LoadFontfile>` or the attribute `require` on `<Layout>`) results in an error.

Also removed in version 6.0:

- Type 1 fonts (`.pfb`): they could only be loaded with the fontforge font loader. Please convert them to OpenType.
- The command line options `--extra-xml` and `--prepend-xml` (configuration keys `extraxml` and `prependxml`): use XInclude instead to split the layout into several files.

### Migrating from luxor and fontforge

If your layout still uses one of the old variants:

- `luxor`: Run the layout with `lxpath` and fix the reported errors. Calculations with units (e.g. `"2cm + 12mm"`) do not conform to the XPath specification and can be expressed with the function [`sd:dimexpr()`]({{< relref "layoutfunctions" >}}).
- `fontforge`: Remove the `fontloader` key from the configuration file and the attribute `mode="fontforge"` on `<LoadFontfile>`; fonts are then loaded with `harfbuzz`. Virtual fonts are no longer supported. Type 1 fonts (`.pfb`) should be converted to OpenType.

## Setting requirements in the layout file

The `require` attribute on the [`<Layout>`]({{< relref "/reference/commands/layout" >}}) command can be used to ensure that a specific configuration is active.
This is useful when layout files are exchanged between different installations:

```xml
<Layout
    xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en"
    require="lxpath,harfbuzz">
```

The available options are:

| Key | Description |
| --- | --- |
| `lxpath` | The XPath parser `lxpath` (always active, accepted for compatibility). |
| `harfbuzz` | The font loader `harfbuzz` (always active, accepted for compatibility). |
| `luxor` | The old XPath parser (removed in version 6.0, raises an error). |
| `fontforge` | The old font loader (removed in version 6.0, raises an error). |
