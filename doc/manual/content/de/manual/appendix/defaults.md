---
title: "Voreinstellungen des speedata Publishers"
weight: 10
type: docs
---


Der speedata Publisher definiert einige Voreinstellungen, die in der Layout-Datei überschrieben werden können.
Sie betreffen die Farben, Schriftarten und Seitenränder.

## Schriftarten

Die Distribution enthält die freien Schriftarten TeXGyreHeros, einem hochwertigen Helvetica-Klon, CrimsonPro und CamingoCode in den Varianten Normal, Fett, Kursiv und Fettkursiv.
Die Definitionen sind folgende:

```xml
<LoadFontfile
       name="TeXGyreHeros-Regular"
       filename="texgyreheros-regular.otf" />
<LoadFontfile
       name="TeXGyreHeros-Bold"
       filename="texgyreheros-bold.otf" />
<LoadFontfile
       name="TeXGyreHeros-Italic"
       filename="texgyreheros-italic.otf" />
<LoadFontfile
       name="TeXGyreHeros-BoldItalic"
       filename="texgyreheros-bolditalic.otf" />

<LoadFontfile
       name="CamingoCode-Bold"
       filename="CamingoCode-Bold.ttf" />
<LoadFontfile
       name="CamingoCode-BoldItalic"
       filename="CamingoCode-BoldItalic.ttf" />
<LoadFontfile
       name="CamingoCode-Italic"
       filename="CamingoCode-Italic.ttf" />
<LoadFontfile
       name="CamingoCode-Regular"
       filename="CamingoCode-Regular.ttf" />

<LoadFontfile
       name="CrimsonPro-Bold"
       filename="CrimsonPro-Bold.ttf" />
<LoadFontfile
       name="CrimsonPro-BoldItalic"
       filename="CrimsonPro-BoldItalic.ttf" />
<LoadFontfile
       name="CrimsonPro-Italic"
       filename="CrimsonPro-Italic.ttf" />
<LoadFontfile
       name="CrimsonPro-Regular"
       filename="CrimsonPro-Regular.ttf" />
```

Die Schriftfamilie `text`, die die voreingestellte Schriftart für Text ist:

```xml
<DefineFontfamily name="text" fontsize="10" leading="12">
  <Regular    fontface="TeXGyreHeros-Regular"/>
  <Bold       fontface="TeXGyreHeros-Bold"/>
  <Italic     fontface="TeXGyreHeros-Italic"/>
  <BoldItalic fontface="TeXGyreHeros-BoldItalic"/>
</DefineFontfamily>
```

Durch Überschreiben der Schriftfamilie `text` kann eine andere Voreinstellung festgelegt werden.

Die Fontaliase sind auch für die Standardschrift definiert:

* `TeXGyreHeros-Regular` -> sans
* `TeXGyreHeros-Bold` -> sans-bold
* `TeXGyreHeros-Italic` -> sans-italic
* `TeXGyreHeros-BoldItalic` -> sans-bolditalic

* `CrimsonPro-Regular` -> serif
* `CrimsonPro-Bold` -> serif-bold
* `CrimsonPro-Italic` -> serif-italic
* `CrimsonPro-BoldItalic` -> serif-bolditalic

* `CamingoCode-Regular` -> monospace
* `CamingoCode-Bold` -> monospace-bold
* `CamingoCode-Italic` -> monospace-italic
* `CamingoCode-BoldItalic` -> monospace-bolditalic

Die mit dem Modus `harfbuzz` aktivierten OpenType Features sind:

| Feature | Bedeutung |
| --- | --- |
| `abvm` | Above-base Mark Positioning |
| `blwm` | Below-base Mark Positioning |
| `calt` | Contextual Alternates |
| `ccmp` | Glyph Composition/Decomposition |
| `clig` | Contextual Ligatures |
| `curs` | Cursive Positioning |
| `dist` | Distances |
| `kern` | Kerning |
| `locl` | Localized Forms |
| `mark` | Mark Positioning |
| `mkmk` | Mark to Mark Positioning |
| `rclt` | Required Contextual Alternates |
| `rlig` | Required Ligatures |


## Textformate

Die folgenden Textformate sind definiert:

```xml
<DefineTextformat name="text" alignment="justified"/>
<DefineTextformat name="centered" alignment="centered" />
<DefineTextformat name="left" alignment="leftaligned"/>
<DefineTextformat name="right" alignment="rightaligned"/>

<DefineTextformat name="__justified" alignment="justified"/>
<DefineTextformat name="__centered" alignment="centered" />
<DefineTextformat name="__leftaligned" alignment="leftaligned"/>
<DefineTextformat name="__rightaligned" alignment="rightaligned"/>
```

Die letzten vier werden in Tabellen benutzt. Siehe [den Abschnitt über Textformate in Tabellen]({{< relref "textformat" >}}).

## Seitenformat

Das voreingestellte Seitenformat ist DIN A4 (210mm × 297mm).
Die Seitenvorlage für alle Seiten ist wie folgt definiert:

```xml
<Pagetype name="Default Page" test="true()">
  <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
</Pagetype>
```

Das Seitenraster beträgt 10mm × 10mm.

## Farben

Die bekannten CSS-Farben sind im RGB-Farbraum definiert. Die Farben `black` und `white` sind im Graustufen-Farbraum definiert. Siehe auch den Befehl [`DefineColor`]({{< relref "/reference/definecolor" >}}), dort sind die vordefinierten Farben aufgelistet.

Die Sonderfarben HKS 1-97 sowie viele Pantone Farben sind schon mit ihren CMYK-Werten definiert.

## Dokumentabschnitte

Zwei Abschnitte sind vordefiniert:

```xml
<DefineMatter name="mainmatter" label="decimal" resetbefore="yes" />
<DefineMatter name="frontmatter" label="lowercase-romannumeral" />
```
