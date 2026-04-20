---
title: Objekte ausgeben
weight: 32
type: docs
---


Es gibt zwei Befehle, Objekte auszugeben.
Der eine heißt `<Output>` und wird nur für Text benutzt, der auf mehrere Seiten umbrechen soll.
Alle anderen Objekte (Bilder, Tabellen, Barcodes, ...) werden über den Befehl `<PlaceObject>` ausgegeben.
Die Parameter werden im Detail in der Befehlsreferenz (siehe [Befehl `<PlaceObject>`]({{< relref "/reference/placeobject" >}})) aufgeführt.
Hier folgen einige Beispiele und Anwendungsmöglichkeiten.

Im einfachsten Fall ist der Befehl wie folgt zu benutzen:

```xml
<Record element="data">
  <PlaceObject>
    <Image file="_samplea.pdf" width="5"/>
  </PlaceObject>
</Record>
```

Hier wird ein Bild eingebunden mit dem angegebenen Dateinamen und einer vorgegebenen Breite.
Das Bild `_samplea.pdf` (mit Unterstrich am Anfang) ist in der Distribution enthalten und kann als Platzhalter benutzt werden.


## Rasterbasierte Platzierung von Objekten

Im Abschnitt [raster]({{< relref "/manual/basics/grid" >}}) wird ausführlich auf das Gestaltungsraster eingegangen.
Hier soll nur soviel erwähnt werden: Das Raster hilft einerseits beim Positionieren der Objekte (leichtes Anordnen der Objekte) als auch bei der Suche nach dem passenden Platz.
Rasterzellen werden nicht von zwei Objekten gleichzeitig belegt, außer man erlaubt dies explizit.

Dies ist ein Beispiel für die rasterbasierte Ausgabe.
Die Angaben bei `row` und `column` sind Koordinaten im Seitenraster, wobei die linke obere Ecke die Position 1,1 ist.

```xml
<PlaceObject row="4" column="5">
    <Image file="_samplea.pdf" width="5"/>
</PlaceObject>
```


## Reihenfolge der Objekte

Die Reihenfolge der Ausgabe der einzelnen Objekte ist wichtig: die Objekte werden übereinander gezeichnet. Das heißt, Objekte, die später ausgegeben werden, überdecken die vorhergehenden Objekte.
Das kann man sich bei Hintergrundbildern zunutze machen.
In `<AtPageCreation>` kann man ein Briefpapier oder Seitenkopf ausgeben, der dann in der eigentlichen Datenverarbeitung mit echtem Inhalt überschrieben wird.
Oder man kann eine vorgefertigte Seite einbinden und mit der korrekten Seitenzahl versehen:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data">
    <PlaceObject row="1" column="1">
      <Image file="agb.pdf" width="180mm" height="280mm"/>
    </PlaceObject>
    <PlaceObject
      column="1"
      row="{sd:number-of-rows()}">
      <Textblock textformat="right">
        <Paragraph>
          <Value select="sd:current-page()"/>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

Hier wird erst die Seite eingebunden und dann in der letzten Zeile rechtsbündig die aktuelle Seitenzahl »eingedruckt«.


## Höhe und Breite der Objekte

Bilder, Barcodes, Boxen etc. haben feste Breiten und Höhen.
Texte und Tabellen nutzen die noch vorhandene Breite aus.
D. h. die Breite ist die Differenz zwischen Anzahl der Rasterzellen und der Startspalte plus 1.
Bei einer exemplarischen Breite von 15 Rasterkästchen und einer Startspalte von 6 ist die Textbreite 10, sofern keine andere Angabe gemacht wird.

Benötigt ein Objekt (wie z. B. Bilder) eine Breiten- oder Höhenangabe, kann diese entweder absolut (z. B. 5cm) gegeben werden oder in Rasterzellen.

## Textblock

Das ist ein rechteckiger Textbereich, der nicht auf mehrere Seiten umbrochen wird.
Textblöcke sind ideal für Seitenzahlen, kurze Beschreibungen, Kolumnentitel und alle anderen Einheiten, wo ein Seitenumbruch nicht erwünscht ist.

Ein `<Textblock>` kann einen oder mehrere Absätze (`<Paragraph>`) enthalten.
Sowohl der Textblock selbst als auch Absätze können Informationen über die benutzte Schriftart, Farben und Textformate enthalten.
Sind diese in den Absätzen deklariert, so haben die Vorrang vor denen, die im Textblock angegeben sind.

```xml
<Textblock color="blue">
  <Paragraph color="green">
    <Value>green text</Value>
  </Paragraph>
  <Paragraph>
    <Value>this text is in blue (given by Textblock)</Value>
  </Paragraph>
</Textblock>
```

Weitere Formatierungsmöglichkeiten sind im Abschnitt [einbindungschriftarten]({{< relref "fonts" >}}) und [textformatierung]({{< relref "textformatting" >}})  beschrieben.

![Angaben in den Absätzen überschreiben die Werte im Textblock](/img/textblock-paragraph.png)

Die vollständige Beschreibung von `<Textblock>` ist [in der Referenz (Abschnitt Textblock)]({{< relref "/reference/textblock" >}}) zu finden.
Für Texte, die über Seitengrenzen hinweg umbrechen dürfen, gibt es den Befehl `<Text>` als Kindelement von `<Output>`, beschrieben im nächsten Abschnitt.

## Texte mit Seitenumbruch

Texte mit Seitenumbruch werden nicht wie die anderen Objekte mit `<PlaceObject>`, sondern mit `<Output>` ausgegeben.
Die Syntax dafür ist

```xml
<Output>
  <Text>
    <Paragraph>
      <Value>...</Value>
    </Paragraph>
    <Paragraph>
      <Value>...</Value>
    </Paragraph>
  </Text>
</Output>
```

Neben der Besonderheit, dass dieser Text auf mehrere Seiten umbrechen kann, ist er auch in der Lage, Objekte zu umfließen.
Eine detaillierte Beschreibung dieser Eigenschaft ist im Abschnitt [umfliessenvonbildern]({{< relref "wrappingaroundobjects" >}}) gegeben.

## HTML

HTML-Inhalte können auf verschiedene Arten ausgegeben werden. Am einfachsten ist die Verwendung des `<HTML>`-Befehls direkt innerhalb von `<Output>`:

```xml
<Output>
  <HTML>
    <p>Ein Absatz mit <b>fettem</b> und <i>kursivem</i> Text.</p>
  </HTML>
</Output>
```

HTML kann auch innerhalb von `<Paragraph>` in einem `<Textblock>` oder `<Text>` verwendet werden. In diesem Fall kommt das HTML aus den Daten:

```xml
<Record element="Paragraph">
  <PlaceObject>
    <Textblock>
      <Paragraph>
        <Value select="." />
      </Paragraph>
    </Textblock>
  </PlaceObject>
</Record>
```

Mit Daten wie:

```xml
<Paragraph><![CDATA[<ul><li>Punkt 1</li><li>Punkt 2</li></ul>]]></Paragraph>
```

Eine ausführliche Beschreibung der HTML-Funktionen einschließlich CSS-Styling ist im Abschnitt [HTML]({{< relref "/manual/webformats/html" >}}) zu finden.

## Einführung in Tabellen

Das im Publisher benutzte Tabellenmodell entspricht in etwa dem von HTML bekannten Modell.
Die Zeilen werden mit `<Tr>` angegeben und die einzelnen Spalten mit `<Td>`.

Die Struktur einer einfachen Tabelle ohne Spaltendeklaration, Kopf- und Fußzeile sieht wie folgt aus:

```xml
<PlaceObject>
  <Table>
    <Tr>
      <Td>...</Td>
      <Td>...</Td>
    </Tr>
    <Tr>
      <Td>...</Td>
      <Td>...</Td>
    </Tr>
  </Table>
</PlaceObject>
```

Die Inhalte der Tabellenzellen können Absätze, Bilder und andere Objekte sein.

```xml
<Td>
  <Paragraph>
    <Value>...</Value>
  </Paragraph>
</Td>

<Td>
  <Image file="ocean.pdf" width="4"/>
</Td>
```

Eine praktische Eigenschaft der Tabellen ist, dass sie über mehrere Seiten laufen können, auch mit wiederholenden Kopf- und Fußzeilen.
In den Tabellenzellen können Texte, Bilder, Barcodes, etc. stehen; also alles, was auch in `<PlaceObject>` enthalten sein kann.
Einzelne Zellen werden niemals auf mehrere Seiten umbrochen, d. h. sie werden als rechteckiges Kästchen gesetzt, auch wenn die Inhalte einen Umbruch erlauben würden (z. B. Texte oder Tabellen).

Dem Thema Tabellen ist [ein eigenes Kapitel gewidmet]({{< relref "tables" >}}).

## Bilder

Bilder einbinden ist, wie schon eingangs gezeigt, sehr leicht. Der Befehl dafür lautet `<Image>`:

```xml
<PlaceObject>
    <Image file="_samplea.pdf" width="5cm"/>
</PlaceObject>
```

Bilder können in den Formaten PDF, JPEG und PNG vorliegen und eingebunden werden.
Alle anderen Formate wie z. B. Tiff oder SVG müssen vorher konvertiert werden.

Der Befehl zum Einbinden der Bilder ist sehr mächtig und wird ausführlich in einem eigenen Abschnitt (Kapitel [bildereinbinden]({{< relref "imagesandgraphics" >}})) beschrieben. Die [Referenz]({{< relref "/reference/image" >}}) enthält eine kurze Beschreibung aller Möglichkeiten.

## Rechteckige Flächen (`<Box>`)

Rechteckige Flächen werden mit dem Befehl `<Box>` erzeugt.

```xml
<PlaceObject>
  <Box width="4" height="3" background-color="limegreen"/>
</PlaceObject>
```

![Ein buntes Kästchen, ausgegeben mit `<Box>`](/img/zitronengruen.png)

Oftmals werden Kästchen für farbige Flächen hinter einem Text oder einer Tabelle benutzt.
Dann muss die Belegung der Rasterzellen ausgeschaltet werden (`allocate="no"` bei `<PlaceObject>`), sonst kommt es zu einer Warnung wegen der doppelt belegten Fläche im PDF (siehe Abschnitt [raster]({{< relref "/manual/basics/grid" >}})).
Ein Beispiel für die Nutzung von Boxen als Hintergrund ist im Abschnitt über [griffmarken]({{< relref "thumbindex" >}}) zu finden.
Dort wird auch der Parameter `bleed` erläutert, der dazu dient, den Kasten in eine oder mehrere Richtungen zu vergrößern, sofern sich diese am Seitenrand befinden.

## Kreis

Kreise werden mit dem Befehl `<Circle>` ausgegeben:
```xml
<Record element="data">
  <PlaceObject column="5" row="5">
    <Circle radiusx="3" background-color="goldenrod"/>
  </PlaceObject>
  <PlaceObject column="5" row="5">
    <Circle radiusx="1pt" background-color="black"/>
  </PlaceObject>
</Record>
```

In diesem Beispiel ist der Radius des großen Kreises 3 Rasterkästchen und der Mittelpunkt des Kreises liegt in der linken oberen Ecke des Kästchens (5,5).
Damit fängt er in der zweiten Spalte und in der zweiten Zeile an und erstreckt sich bis zur siebten Spalte und Zeile.
Kreise haben die besondere Eigenschaft, dass keine Rasterzellen als *belegt* markiert werden.


![Kreis mit Radius 3 und Mittelpunkt bei (5,5)](/img/kreismitmittelpunkt.png)


## Linien (`<Rule>`)

Es gibt horizontale und vertikale Linien.
Diese können eine Liniendicke haben, eine Farbe und eine Länge.
Linien können durchgezogen und gestrichelt sein:

```xml
<PlaceObject column="2" row="2">
  <Rule direction="horizontal" length="4" dashed="yes"/>
</PlaceObject>
```

Linien werden immer oben links im Kästchen ausgerichtet.


![Eine gestrichelte Linie.](/img/gestricheltelinie.png)

## Rahmen

Der Rahmen (wie die Transformation weiter unten) ist ein besonderes Objekt, das man über ein anderes Objekt legt.
Ein Rahmen (`<Frame>`) beinhaltet immer ein anderes Objekt, beispielsweise ein Bild.

```xml
<PlaceObject>
  <Frame
    border-bottom-left-radius="8pt"
    border-bottom-right-radius="8pt"
    border-top-left-radius="8pt"
    border-top-right-radius="8pt"
    framecolor="darkseagreen"
    rulewidth="2pt">
    <Image file="_samplea.pdf" width="4"/>
  </Frame>
</PlaceObject>
```

Man sieht, dass der Rahmen als Clipping-Pfad funktioniert, die Teile außerhalb werden ausgeblendet.
Den Rahmen (`rulewidth`) kann man auch auf Null setzen und somit unsichtbar machen, dann wird nur der Inhalt beschnitten.

![Rahmen mit Radius 8pt und Linienstärke von 2 Punkt.](/img/eagle-frame.png)

## Transformation

![Die vier grundlegenden Transformationen (aus der PDF-Spezifikation)](/img/transformation.png)

Wie der Rahmen ist die Transformation ein umschließendes Element.
Das bedeutet, dass das Element noch einen Inhalt haben muss, wie z. B. ein Bild.

Man gibt bei der Transformation eine Matrix an, die aus sechs Zahlen besteht in der Form »a b c d e f«.
Die Transformation von einem Koordinatensystem in ein anderes wird über folgende 3x3 Matrix abgebildet:

$$
\begin{bmatrix} x' & y' & 1 \end{bmatrix} = \begin{bmatrix} x & y & 1 \end{bmatrix} \times \begin{bmatrix} a & b & 0 \\ c & d & 0 \\ e & f & 1 \end{bmatrix}
$$

Wenn man aus den Koordinaten x und y die neuen Koordinaten x' und y' errechnen will, kann man das auch über die folgende Formeln machen:

$$
\begin{aligned}
x' &= a \times x + c \times y + e \\
y' &= b \times x + d \times y + f
\end{aligned}
$$

Es gibt folgende grundlegende Transformationsarten (siehe Abbildung):

1. Verschiebungen (translation) werden mit den Werten \(1\; 0\; 0\; 1\; t_x\; t_y\) beschrieben
2. Die Skalierung (scaling) wird mit \(s_x\; 0\; 0\; s_y\; 0\; 0\) angegeben
3. Drehungen (rotation) können mit \(\cos\theta\; \sin\theta\; {-\sin\theta}\; \cos\theta\; 0\; 0\) erreicht werden
4. Scherungen (skew) sind durch \(1\; \tan\alpha\; \tan\beta\; 1\; 0\; 0\) beschrieben.
5. Die unverändernde Transformation ist \(1\; 0\; 0\; 1\; 0\; 0\) (identische Abbildung).

```xml
<PlaceObject>
  <Transformation matrix="1.8 0.2 0.2 0.8 0 0 ">
    <Image file="ocean.pdf" width="4"/>
  </Transformation>
</PlaceObject>
```


![Scherung und Skalierung durch die Transformationsmatrix.](/img/eagle-transform.png)

## Spiegeln von Objekten

Mit dem Befehl Transformation können Objekte auch gespiegelt werden. Das kann man entweder mit der Transformationsmatrix oder mit dem Attribut `flip` steuern:

```xml
<PlaceObject>
    <Transformation flip="vertical">
        <Image width="3cm" file="ocean.pdf" />
    </Transformation>
</PlaceObject>
```

Erlaubt sind die Werte `none`, `horizontal`, `vertical` und `both`.

## Barcodes, QR-Codes {{< profeature "Verfügbar im PRO-Paket" >}}

Barcodes bzw. QR-Codes werden über den Befehl `<Barcode>` eingebunden:

```xml
<PlaceObject>
  <Barcode select="'Hello world'" type="QRCode" width="5"/>
</PlaceObject>
```

Die Ausgabe ist wie erwartet

![Hallo Welt in Pixeln](/img/qrcode-hallowelt.png)

Es lassen sich Barcodes in der Kodierung »EAN13« und »Code 128« ausgeben.

## Beschneiden von Bildern

Seit Version 4.11.3 kann der speedata Publisher Bilder und andere Objekte beschneiden. Das resultierende Objekt ist kleiner als das Original, sofern die Methode `clip` (Voreinstellung) gewählt ist. Andernfalls (Methode `frame`) ist das resultierende Objekt genau so groß wie das Original, es wird nur ein kleinerer Ausschnitt ausgegeben.

Ein Benutzer hat eine schöne Erklärung der Unterschiede zwischen den Methoden `clip` und `frame`:

Wenn der _Publisher_ eine Schere hätte, würde `clip` das Bild selber beschneiden und `frame` würde einen Rahmen (Passepartout) mit der Öffnung der angegebenen Werte schneiden und über das Bild legen.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">
  <Pageformat height="14cm" width="11cm" />

  <Record element="data">
    <PlaceObject>
      <Clip left="1cm" right="1cm" top="1cm" bottom="2cm" method="clip">
        <Image width="5cm" file="_sampleb.pdf" />
      </Clip>
    </PlaceObject>
    <PlaceObject column="5" >
      <Image width="5cm" file="_sampleb.pdf" />
    </PlaceObject>
  </Record>
</Layout>
```

![Ein beschnittenes und ein unbeschnittenes Bild.](/img/outputobjects-clip.png)

