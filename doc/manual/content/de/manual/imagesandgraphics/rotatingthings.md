---
title: "Rotation von Inhalten"
weight: 52
type: docs
---


Objekte, die mit `PlaceObject` ausgegeben werden, können gedreht werden.
Dazu gibt es das Attribut `rotate`, das einen Winkel (in Grad) erwartet, wobei positive Werte eine Drehung im Uhrzeigersinn bewirken.

```xml
    <PlaceObject rotate="10">
      <Image file="_sampleb.pdf" width="3"/>
    </PlaceObject>
```

Wenn ein Objekt gedreht wird, muss man festlegen, um welchen Punkt es sich drehen soll.
Die Voreinstellung ist die linke obere Ecke.
Mit den Attributen `origin-x` (`left`, `center` und `right`) und `origin-y` (`top`, `center`, `bottom`) kann die Drehachse festgelegt werden.
Neben diesen Werten sind auch die Zahlen von 0 bis 100 möglich, die linke obere Ecke ist 0,0 und rechts unten ist 100, 100.
In Abbildung  sieht man, dass die Drehachse oben links ist.

![Das Bild wird um 10 Grad gedreht. Ein negativer Wert würde die Drehung gegen den Uhrzeigersinn vornehmen.](/img/rotieren.png)

{{< callout >}}
Im [Beispiele-Repository auf Github](https://github.com/speedata/examples/) gibt es im  Verzeichnis `technical` ein Dokument, das den Effekt von `origin-x` und `origin-y` aufzeigt.
{{< /callout >}}


## Rotieren von Bildern

Das Attribut `rotate` gibt es sowohl bei `<PlaceObject>` als auch bei `<Image>`. Das Attribut bei `<Image>` kann Bilder nur in 90-Grad-Schritten drehen (positive Werte: im Uhrzeigersinn). Daher wird in der Praxis die Drehung eher über `<PlaceObject>` gesteuert.
Das folgende Minimalbeispiel zeigt die beiden Varianten:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data">
    <PlaceObject rotate="-90">
      <Image file="_sampleb.pdf" width="3cm"/>
    </PlaceObject>
    <ClearPage/>
    <PlaceObject>
      <Image file="_sampleb.pdf" width="3cm"  rotate="-90"/>
    </PlaceObject>
  </Record>
</Layout>
```

Zu beachten: die Drehung kann sich auch auf angegebene Bildmaße auswirken.

Das nachfolgende Beispiel dreht ein Bild um 90 Grad gegen den Uhrzeigersinn, wenn es sich um ein Hochformat-Bild handelt.
Mit dem XPath-Befehl `sd:aspectratio(<Dateiname>)` kann man das Seitenverhältnis eines Bildes ermitteln.
Wenn es größer als 1 ist, dann handelt es sich um ein Bild im Querformat.
Das zweite Bild aus der Datensatzdatei wird um 90° gegen den Uhrzeigersinn gedreht.

```xml
<data>
  <img file="_samplea.pdf" />
  <img file="_sampleb.pdf" />
</data>
```
{{% codecaption %}}Datensatzdatei{{% /codecaption %}}

```xml
<Layout xmlns:sd="urn:speedata:2009/publisher/functions/en"
  xmlns="urn:speedata.de:2009/publisher/en">

  <Record element="data">
    <ForAll select="img">
      <PlaceObject>
        <Image file="{@file}" width="5"
          rotate="{if ( sd:aspectratio(@file) &lt; 1 ) then '-90' else '0'}"/>
      </PlaceObject>
    </ForAll>
  </Record>
</Layout>
```
{{% codecaption %}}Das Bild wird um 90 Grad gedreht, wenn es ein hochformatiges Bild ist.{{% /codecaption %}}

![Das zweite Bild wird um 90° gedreht, weil es im Hochformat ist.](/img/drehungaspectratio.png)

{{< callout >}}
Die geschweiften Klammern bei `file` und `rotate` bedeuten, dass in den XPath-Modus gesprungen wird, um die XPath-Ausdrücke (Zugriff auf das Attribut `file` und die Wenn-Dann-Abfrage) auszuwerten. Mehr dazu im Abschnitt [XPath- und Layoutfunktionen]({{< relref "/reference/xpath/xpath" >}}).
{{< /callout >}}

_Achtung: ist das Bild im Argument von `sd:aspectratio()` nicht im Dateisystem vorhanden, wird der Wert von dem Platzhalterbild (Abschnitt [Bild nicht gefunden?]({{< relref "/manual/imagesandgraphics#bild-nicht-gefunden" >}})) genommen. Um zu überprüfen, ob ein Bild überhaupt vorhanden ist, kann man den Befehl `sd:file-exists(<Dateiname>)` benutzen._

## Rotieren über Transformation

Über den Befehl `<Transformation>` (siehe Abschnitt [Transformation]({{< relref "outputtingobjects#transformation" >}}) und in der Referenz die [Befehlsbeschreibung]({{< relref "/reference/commands/transformation" >}})) kann man auch Inhalte drehen.
Die Matrix hat die Form »cos θ sin θ −sin θ cos θ 0 0«, für eine Drehung um 90 Grad also »0 1 -1 0 0 0«.
Das wird im Abschnitt [Bild hinter dem Text]({{< relref "/manual/tables#bild-hinter-dem-text" >}}) gezeigt.

