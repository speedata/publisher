---
title: "Schriften verwenden"
weight: 36
type: docs
---


Das Einbinden von Schriftarten in den gängigen Formaten ist sehr einfach.
Unterstützt werden die Formate TrueType und OpenType (Dateien `.ttf` und `.otf`).

{{< callout type="warning" >}}
Type-1-Schriften (Dateien `.pfb`) sind veraltet. Sie werden noch mit dem alten fontforge-Fonthandler geladen, dieser wird aber in einer zukünftigen Version entfernt. Bitte konvertieren Sie Type-1-Schriften nach OpenType.
{{< /callout >}}

Um dem Publisher Schriftarten bekannt zu machen und zu nutzen, sind
zwei Schritte notwendig. Der erste Schritt ist das Laden einer
Schriftdatei:

```xml
<LoadFontfile name="MinionRegular" filename="MinionPro-Regular.otf" />
```

Das weist dem Dateinamen `MinionPro-Regular.otf` den internen Namen `MinionRegular` zu.
Im zweiten Schritt nutzt man dann diese internen Namen, um Familien zu definieren:

```xml
<DefineFontfamily name="textfont" fontsize="9pt" leading="11pt">
  <Regular fontface="MinionRegular"/>
  <Bold fontface="MinionBold"/>
  <Italic fontface="MinionItalic"/>
  <BoldItalic fontface="MinionBoldItalic"/>
</DefineFontfamily>
```

Die letzten drei Schnitte (Fett, Kursiv und Fettkursiv) müssen nicht angegeben werden, wenn sie im Layout nicht benutzt werden.
`fontsize` bezeichnet die Schrifthöhe, `leading` den Abstand zwischen zwei Grundlinien.

![Schriftgröße und Zeilenabstand](/img/14-fontsize-leading.png)

Benutzt wird die Schriftart auf verschiedene Weise: in den Befehlen  `<Textblock>`, `<Text>`, `<Paragraph>`, `<Table>`, `<NoBreak>` und `<Barcode>` kann mit dem Attribut `fontfamily` eine Schriftart mitgegeben werden, z. B. `<Paragraph fontfamily="textschrift">`.
Temporär kann mit dem Befehl `<Fontface fontfamily="...">` auf eine andere Familie umgeschaltet werden:

```xml
<Paragraph>
  <Fontface fontfamily="title">
    <Value>Preface</Value>
  </Fontface>
  <Value> more text</Value>
</Paragraph>
```

## Textauszeichnung im Layoutregelwerk

Um auf die Schnitte Fett, Kursiv und Fett-kursiv umzuschalten, gibt es verschiedene Möglichkeiten.
Die direkteste ist mit den Befehlen `B` und `I` umzuschalten, diese können auch ineinander geschachtelt werden:

```xml
<PlaceObject>
  <Textblock fontfamily="textfont">
    <Paragraph>
      <Value>A wonderful </Value>
      <B><Value>serenity</Value></B>
      <Value> has taken possession </Value>
      <I><Value>of my</Value>
        <Value> </Value>
        <B><Value>entire soul,</Value></B>
      </I>
      <Value> like these sweet mornings.</Value>
    </Paragraph>
  </Textblock>
</PlaceObject>
```

![Auszeichnungen im Layout. Unterstreichen (nicht gezeigt) geht mit dem Befehl `<U>`.](/img/14-fonts.png)

## Textauszeichnung in den Daten

Sind in den Daten Auszeichnungen vorhanden (z. B. als HTML-Tags), dann geht das prinzipiell genau so:

```xml
<PlaceObject>
  <Textblock fontfamily="textschrift">
    <Paragraph>
      <Value select="."/>
    </Paragraph>
  </Textblock>
</PlaceObject>
```

mit den dazugehörigen Daten:

```xml
<data>A wonderful <b>serenity</b> has taken possession
  <i>of my <b>entire soul,</b></i> like these sweet
  mornings.</data>
```

Das Ergebnis ist dasselbe wie oben.
In den Daten können die Tags auch groß geschrieben werden: `<B>` anstatt `<b>`.
Schachtelung ist ebenfalls erlaubt und auch hier wird mit `<u>` unterstrichen.

{{< callout >}}
Sollten die Daten nicht als wohlgeformtes XML sondern beispielsweise im HTML Format vorliegen, kann man die Layoutfunktion `sd:decode-html()` benutzen, sie zu interpretieren.
{{< /callout >}}

## Konturschrift

Mit dem Attribut `font-outline` kann man die Linienstärke für eine Konturschrift angeben:

```xml
<PlaceObject>
    <Textblock>
        <Paragraph font-outline="0.3pt">
            <Value>Hello nice world</Value>
        </Paragraph>
    </Textblock>
</PlaceObject>
```

![Eine Konturschrift erzeugt man mit der Angabe einer Liniendicke mit dem Attribut `font-outline` bei Paragraph.](/img/outlinehelloworld.png)

## Zeichen über Glyph-ID ausgeben

Mit der Funktion `sd:symbol()` können einzelne Glyphen anhand ihrer ID aus dem aktuellen Font ausgegeben werden. Das ist nützlich, wenn ein Zeichen nicht über Unicode erreichbar ist, z.B. bei Symbolfonts oder dekorativen Schriften:

```xml
<Paragraph>
  <Value select="sd:symbol(123, 444)" />
</Paragraph>
```

Die Glyph-IDs können z.B. mit Fonttools oder einem Fonteditor ermittelt werden.

## OpenType Features

Das OpenType Format kennt sogenannte OpenType Features, wie z. B. Mediävalziffern oder Kapitälchen.
Manche dieser Features können bei `<LoadFontfile>` aktiviert werden.

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <!-- Mediävalziffern -->
  <LoadFontfile
    name="MinionRegular-osf"
    filename="MinionPro-Regular.otf"
    oldstylefigures="yes" />

  <!-- Kapitälchen -->
  <LoadFontfile
    name="MinionRegular-smcp"
    filename="MinionPro-Regular.otf"
    smallcaps="yes" />

  <DefineFontfamily name="osftext" fontsize="10" leading="12">
    <Regular fontface="MinionRegular-osf"/>
  </DefineFontfamily>

  <DefineFontfamily name="smcptext" fontsize="10" leading="12">
    <Regular fontface="MinionRegular-smcp"/>
  </DefineFontfamily>

  <Record element="data">
    <PlaceObject>
      <Textblock>
        <Paragraph fontfamily="osftext">
          <Value>Text with oldstyle figures 1234567890</Value>
        </Paragraph>
        <Paragraph fontfamily="smcptext">
          <Value>Text with small caps 1234567890</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

![Mediävalziffern (oben) machen das Lesen der Ziffern oftmals angenehmer. Echte Kapitälchen (unten) unterscheiden sich deutlich von rechnerisch verkleinerten Großbuchstaben. Die Strichstärke und Proportionen müssen angepasst werden. Je nach verwendeter Schriftart schaltet `smallcaps` auch auf  »Mediävalziffern« um.](/img/osfsmcp.png)

Darüber hinaus können weitere OpenType Features mit dem Attribut `features` eingestellt werden, z.B.

```xml
<LoadFontfile name="CrimsonPro-Regular"
  filename="CrimsonPro-Regular.ttf" />
<LoadFontfile name="CrimsonPro-Regular-frac"
  filename="CrimsonPro-Regular.ttf"
  features="+frac" />
```

![Oben der Text ohne das OpenType feature `frac`, unten mit.](/img/frac-feature-hb.png)

Eine Beschreibung aller OpenType Features findet sich unter
https://docs.microsoft.com/en-us/typography/opentype/spec/featurelist.
Die voreingestellten Features sind die, die im  [Harfbuzz Handbuch](https://harfbuzz.github.io/shaping-opentype-features.html) beschrieben sind, ohne `liga`.

## Variable Fonts

Variable Fonts sind Schriftdateien, die mehrere Designachsen in einer einzigen Datei enthalten.
Anstatt für jeden Schnitt (z.B. Thin, Regular, Bold, Black) eine separate Datei zu benötigen, kann man aus einer einzigen Datei beliebig viele Instanzen mit verschiedenen Achsenwerten erzeugen.

Häufige Achsen sind:

- `wght` – Gewicht (z.B. 100 = Thin, 400 = Regular, 700 = Bold, 900 = Black)
- `wdth` – Breite (z.B. 75 = Condensed, 100 = Normal, 125 = Expanded)
- `opsz` – Optische Größe
- `ital` – Kursiv
- `slnt` – Neigung

Für die häufigsten Achsen `wght` und `wdth` gibt es Abkürzungen als Attribute:

```xml
<LoadFontfile name="MyFont-Thin"
  filename="MyFont-Variable.ttf" weight="100" />
<LoadFontfile name="MyFont-Regular"
  filename="MyFont-Variable.ttf" weight="400" />
<LoadFontfile name="MyFont-Bold"
  filename="MyFont-Variable.ttf" weight="700" />
```

Für beliebige Achsen (auch benutzerdefinierte) kann das Kind-Element `<Axis>` verwendet werden:

```xml
<LoadFontfile name="MyFont-SemiboldCondensed"
              filename="MyFont-Variable.ttf">
  <Axis name="wght" value="600" />
  <Axis name="wdth" value="75" />
</LoadFontfile>
```

Beide Varianten können kombiniert werden. Die Attribute `weight` und `width` haben bei Konflikten Vorrang vor gleichnamigen `<Axis>`-Elementen:

```xml
<LoadFontfile name="MyFont-LightOptical12"
              filename="MyFont-Variable.ttf" weight="300">
  <Axis name="opsz" value="12" />
</LoadFontfile>
```

Die erzeugten Instanzen verhalten sich danach wie normale statische Schriftdateien und können in `<DefineFontfamily>` wie gewohnt verwendet werden:

```xml
<LoadFontfile name="Text-Regular"
  filename="MyFont-Variable.ttf" weight="400" />
<LoadFontfile name="Text-Bold"
  filename="MyFont-Variable.ttf" weight="700" />

<DefineFontfamily name="text" fontsize="10pt" leading="12pt">
  <Regular fontface="Text-Regular" />
  <Bold fontface="Text-Bold" />
</DefineFontfamily>
```

## In welchem Verzeichnis müssen die Schriftdateien liegen?

Die Organisation der Dateien, und damit der Schriftarten, wird im Verzeichnis [Dateiorganisation]({{< relref "fileorganization" >}}) beschrieben.
Mit `sp --systemfonts`  beim Aufruf  des Publishers kann man auf die systemweiten Schriftdateien zugreifen.

## Tipps und Tricks

Um sich Arbeit bei der Schriftdefinition zu sparen, kann man den Befehl

```
$ sp list-fonts --xml
```

benutzen.
Dieser listet dann alle gefundenen Schriftdateien auf, zusammen mit einer Zeile, die direkt in das Layout übernommen werden kann.

```
$ sp list-fonts --xml
<LoadFontfile name="DejaVuSans-Bold"
              filename="DejaVuSans-Bold.ttf" />
<LoadFontfile name="DejaVuSans-BoldOblique"
              filename="DejaVuSans-BoldOblique.ttf" />
<LoadFontfile name="DejaVuSans-ExtraLight"
              filename="DejaVuSans-ExtraLight.ttf" />
...
```

{{< callout >}}
Wenn keine Schriftart für einen Absatz oder einen Textblock (etc.) angegeben wird, nutzt das System die Schriftfamilie `text`, die im Publisher auch vordefiniert ist und überschrieben werden kann. Siehe den Anhang [Voreinstellungen im Publisher]({{< relref "defaults" >}}).
{{< /callout >}}

## Fehlende Zeichen und Ersatzschriftarten

Die Zeichenvorräte in den Schriftdateien sind meist sehr begrenzt.
Beispielsweise wird der speedata Publisher mit der freien Schriftart »TeXGyreHeros« (einem sehr guten Helvetica-Klon) ausgeliefert.
In der Schriftdatei sind aber nur Zeichen enthalten, die westliche Sprachen abdecken, aber z.B. nicht Griechisch, Arabisch, Chinesisch etc.
Auch die ganzen Unicode-Sonderzeichen wie U+2685 DIE FACE-6 (⚅) sind nicht enthalten.
Wird ein Zeichen angefordert, das in der Schriftart nicht enthalten ist, gibt es eine Fehlermeldung.

```
Error: Glyph f1c7 (hex) is missing from the font "TeXGyreHeros-Regular"
```

Diesen Fehler kann man mit dem Befehl [`<Options>`]({{< relref "/reference/options" >}}) unterdrücken:

```
<Options reportmissingglyphs="no"/>
```

Alternativ dazu kann man auch bei  [`<LoadFontfile>`]({{< relref "/reference/loadfontfile" >}}) eine Ersatzschriftart angeben, die durchsucht wird, sobald ein Zeichen nicht gefunden wird:

```xml
<LoadFontfile name="helvetica" filename="texgyreheros-regular.otf">
  <Fallback filename="fontawesome-webfont.ttf" />
  <Fallback filename="line-awesome.ttf" />
</LoadFontfile>
```

So wird erst die Schriftart `texgyreheros-regular.otf` durchsucht, anschließend `fontawesome-webfont.ttf` und zum Schluss  `line-awesome.ttf`.

## Aliasnamen

Es gibt einen Befehl,  um einen alternativen Namen für einen existierenden Fontnamen zu der Liste der bekannten Fontnamen hinzuzufügen:

```xml
<DefineFontalias existing="..." alias="..."/>
```

Die Befehle

```xml
<LoadFontfile name="DejaVuSerif"
        filename="DejaVuSerif.ttf" />
<LoadFontfile name="DejaVuSerif-Bold"
        filename="DejaVuSerif-Bold.ttf" />
<LoadFontfile name="DejaVuSerif-BoldItalic"
        filename="DejaVuSerif-BoldItalic.ttf" />
<LoadFontfile name="DejaVuSerif-Italic"
        filename="DejaVuSerif-Italic.ttf" />

<DefineFontalias existing="DejaVuSerif" alias="serif"/>
<DefineFontalias existing="DejaVuSerif-Bold" alias="serif-bold"/>
<DefineFontalias existing="DejaVuSerif-Italic" alias="serif-italic"/>
<DefineFontalias existing="DejaVuSerif-BoldItalic"
         alias="serif-bolditalic"/>
```

erlauben es nun, die Schriftfamilien allgemein wie folgt zu definieren:

```xml
<DefineFontfamily name="title" fontsize="15" leading="17">
  <Regular fontface="serif"/>
  <Bold fontface="serif-bold"/>
  <BoldItalic fontface="serif-bolditalic"/>
  <Italic fontface="serif-italic"/>
</DefineFontfamily>
```

also unabhängig von der tatsächlich genutzten Schriftart.
Mit den im Abschnitt [Include]({{< relref "include" >}}) beschriebenen Möglichkeiten kann man nun die Fontdefinition in eine separate Datei auslagern und bei Bedarf schnell zwischen verschiedenen Schriftarten wählen, indem die gewünschten Dateien eingebunden werden.
