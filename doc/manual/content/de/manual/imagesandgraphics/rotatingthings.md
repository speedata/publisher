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

Das Attribut `rotate`  gibt es sowohl bei `<PlaceObject>` als auch bei `<Image>`. Das Attribut bei `<Image>` kann Bilder nur in 90° Schritten drehen. Daher wird in der Praxis die Drehung eher über `<PlaceObject>` gesteuert.


## Rotieren über Transformation

Über den Befehl `<Transformation>` (siehe Abschnitt [objekteausgeben-transformation]({{< relref "outputtingobjects" >}}) und im Anhang die [Befehlsbeschreibung]({{< relref "/reference/transformation" >}})) kann man auch Inhalte drehen.
Die Matrix hat die Form »cos θ sin θ −sin θ cos θ 0 0«, für eine Drehung um 90 Grad also »0 1 -1 0 0 0«.
Das wird im Abschnitt [bildhintertext]({{< relref "tables" >}}) gezeigt.

