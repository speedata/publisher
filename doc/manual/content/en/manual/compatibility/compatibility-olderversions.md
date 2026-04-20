---
title: "Compatibility with older versions"
weight: 230
type: docs
---


The development of the speedata Publisher has one big "mantra": existing setups must work with newer versions of the speedata Publisher without change. So you can always upgrade to the latest version without having to fear that you need to change your layout file.

New features are introduced via new XML tags or attributes.
Existing layout files simply ignore them and continue to work.

## Legacy options

Since version 5, the XPath parser `lxpath` and the font loader `harfbuzz` are the defaults.
The older variants (`luxor` and `fontforge`) are still available but no longer recommended.
If an existing layout requires one of the old variants, it can be activated via the [configuration file]({{< relref "configuration" >}}).

Known differences of the old variants:

- `fontforge`: Supports virtual fonts which can be used to simulate certain font features.
- `luxor`: Can calculate with dimensions (e.g. `"2cm + 12mm"`), which does not conform to the XPath specification but is used in some older layouts.

## Setting requirements in the layout file

The `require` attribute on the [`<Layout>`]({{< relref "/reference/layout" >}}) command can be used to ensure that a specific configuration is active.
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
| `lxpath` | Ensures the XPath parser `lxpath` is used (default since v5). |
| `harfbuzz` | Ensures the font loader `harfbuzz` is used (default since v5). |
| `luxor` | Forces the old XPath parser. |
| `fontforge` | Forces the old font loader. |
