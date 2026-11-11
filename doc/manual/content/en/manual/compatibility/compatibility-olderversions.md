---
title: "Compatibility with older versions"
weight: 230
type: docs
aliases:
  - /en/compatibilityolderversions/
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

## Behavior changes in version 6.0

Some corrections change the line breaks or the placement of existing documents.
They become the standard only with version 6.0.
Until then, a layout without further settings keeps the previous behavior, and you can switch the new behavior on beforehand.

| Behavior | Setting at `<Compatibility>` | Standard from |
| --- | --- | --- |
| Word spaces in ragged text (alignment `leftaligned`, `rightaligned`, `centered`, `start` and `end`) keep their natural width. Up to version 5.9 they may shrink a little, so that a line takes one more word. | `raggednaturalspaces` | 6.0 |

### All behaviors of a version: `defaults`

The attribute `defaults` at [`<Layout>`]({{< relref "/reference/commands/layout" >}}) selects the behavior of a publisher version, in the format major.minor or with the keyword `latest` for the current version:

```xml
<Layout
    xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en"
    defaults="6.0">
```

- `defaults="6.0"` (or `latest`) switches on all behaviors of the table above already now.
- `defaults="5.9"` keeps the previous behavior, also after the upgrade to version 6.0. Use it for layouts whose output must not change.
- Without the attribute, the built-in level of the publisher applies: 5.9 up to the version 5.9.x, 6.0 from version 6.0 on.

Only the root element of the main layout file counts.

### Single behaviors: `<Compatibility>`

The command [`<Compatibility>`]({{< relref "/reference/commands/compatibility" >}}) switches a single behavior, independent of `defaults`.
It takes precedence over `defaults`:

```xml
<Layout
    xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en"
    defaults="6.0">

  <!-- everything as in version 6.0, but the old word spaces in ragged text -->
  <Compatibility raggednaturalspaces="no"/>
```

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
