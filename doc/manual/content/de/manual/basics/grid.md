---
title: "Raster"
weight: 37
type: docs
---


Beim Raster handelt es sich um nicht sichtbare Linien oder Kästchen, an dem Objekte ausgerichtet sind.
Man kennt es beispielsweise vom Zeitungsdruck, wo es oftmals fünf oder sechs Spalten gibt.
Alle Bilder oder Anzeigen füllen dann eine oder mehrere Spalten aus.
Ebenso gibt es in Katalogen häufig Rasterzeilen, die ähnlich funktionieren.
Dadurch erreicht man ein klares Layout.

Der speedata Publisher arbeitet immer mit einem solchen Raster.
Da jede Publikation anders ist, gibt es keine Möglichkeit, eine sinnvolle Vorgabe dafür zu finden.
In der Voreinstellung ist das Raster auf eine Größe von 1cm × 1cm gesetzt.
Es gilt für die Seite sowie alle Positionierungsrahmen und Gruppen.
Anzeigen kann man das Raster mit `sp --grid` oder `<Trace grid="yes"/>` im Layout.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <SetGrid height="12pt" nx="10"/>
  <Trace grid="yes"/>
  <Pageformat width="8cm" height="4cm"/>

  <Record element="data">
    <PlaceObject column="3" row="2">
      <Textblock>
        <Paragraph>
          <Value>Hello world!</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>

</Layout>
```

ergibt

![Einfaches Raster](/img/08-raster.png)

Wenn man genau hinschaut, sieht man, dass der erste und dann jeder fünfte Strich etwas dunkler gezeichnet wird.
Das hilft dabei, Rasterzellen zu zählen, falls das notwendig sein sollte.
Die rote Linie zeigt die Begrenzung der Seite, in der Voreinstellung sind die Ränder jeweils 1cm.

## Positionierung der Objekte im Raster

In dem Beispiel oben sieht man, dass die Angaben bei `row` und `column` sich auf das Raster beziehen, der Ursprung oben links hat die Koordinate 1,1.
Neben dem Platzieren in Rasterkoordinaten gibt es noch die absolute Platzierung: hier lässt sich das Objekt immer exakt an einer ganz bestimmten Stelle im PDF positionieren.
Das eignet sich beispielsweise für Logos oder Hintergrundbilder, die an einer festen Position dargestellt werden sollen.
Diese beiden Varianten sind innerhalb einer Ausgabe mit `<PlaceObject>` nicht kombinierbar: man muss sich für eine der beiden Varianten entscheiden.

```xml
<!-- grid -->
<PlaceObject row="4" column="5">
    <Image file="_samplea.pdf" width="5"/>
</PlaceObject>

<!-- absolute  -->
<PlaceObject row="12mm" column="5cm">
    <Image file="_samplea.pdf" width="5"/>
</PlaceObject>
```
{{% codecaption %}}Rasterbasierte Ausgabe (oben) und absolute Ausgabe (unten). Bei der rasterbasierten Ausgabe sind die Angaben Koordinaten im Seitenraster, wobei die linke obere Ecke die Position 1,1 ist. Bei der absoluten Positionierung ist die Angabe gemessen von der linken oberen Ecke. Sobald eine der beiden Angaben eine Längenangabe ist, wird die absolute Positionierung genommen.{{% /codecaption %}}

Die Angabe von Zeile und Spalte beziehen sich immer auf die linke, obere Ecke des Objekts, sofern nicht mit `hreference`  oder `vreference` festgelegt wird, dass sich die Angabe auf die rechte oder untere Ecke beziehen soll.

Die Objekte richten sich an der oberen und linken Kante der ersten Rasterzelle aus.
Mittels `halign` und `valign` kann man das Objekt auch rechts bzw. unten ausrichten:

```xml
<PlaceObject column="{sd:number-of-columns()}" row="1"
    hreference="right">
  <Image file="logo.pdf" width="2.5"/>
</PlaceObject>

<PlaceObject column="{sd:number-of-columns()}" row="4"
    hreference="right" halign="right">
  <Image file="logo.pdf" width="2.5"/>
</PlaceObject>
```


![Durch die Angabe von `hreference="right"` wird die Spaltenangabe nicht für den linken Rand des Bildes benutzt, sondern für den rechten Rand. Wenn die Breite des Bildes nicht einem Vielfachen der Rasterbreite entspricht, wie in diesem Beispiel, muss zusätzlich mit `halign="right"` noch die Ausrichtung innerhalb der Rasterzelle korrigiert werden (rechtes Logo).](/img/hreferenz.png)

## Festlegen des Rasters

Das Raster wird mit dem Befehl `<SetGrid>` global eingestellt. Z. B.

```xml
<SetGrid height="12pt" width="5mm"/>
```

setzt die Rasterhöhe auf 12 Punkt und die -breite auf 5 Millimeter.
Neben den festen Werten gibt es die Möglichkeit die Anzahl der Rasterzellen horizontal und vertikal festzulegen:

```xml
<SetGrid nx="9" ny="9" />
```

Dies erzeugt eine sogenannte Neunerteilung, die häufig in der Buchgestaltung benutzt wird.
Man kann auch noch Abstände zwischen den Rasterzellen festlegen, wie es z. B. im Zeitungssatz üblich ist:

```xml
<SetGrid width="45mm" dx="3mm" height="12pt" />
```

Wenn das Raster nicht vollständig in den Satzspiegel passt, z. B. bei einer Rasterbreite von 3 Zentimeter und einer Seitenbreite von 10 Zentimeter, führt das zu einem Konflikt im Seitenlayout.
Dadurch wird der rechte bzw. der untere Rand verschoben und passt nicht mit den im Seitentyp angegebenen Werten überein.

## Wofür wird das Raster benötigt?

Ruft man `sp` mit der Option `--show-gridallocation` auf, so sieht man sofort, wofür das Raster auch gut ist.
Belegte Zellen werden intern markiert, so dass kein weiteres Objekt in diesem Bereich platziert werden kann.
Zumindest nicht ohne Fehlermeldung oder dem Hinweis, dass kein Bereich dafür freigehalten werden soll (`allocate="no"` in `<PlaceObject>`).

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <SetGrid height="12pt" nx="10"/>
  <Trace grid="yes" gridallocation="yes"/>
  <Pageformat width="8cm" height="4cm"/>

  <Record element="data">
    <PlaceObject column="3" row="2">
      <Textblock>
        <Paragraph>
          <Value>Hello world!</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>

</Layout>
```


ergibt

![Raster mit Rasterbelegungsanzeige eingeschaltet. Der gelbe Bereich wird intern als »belegt« markiert.](/img/08-raster2.png)


Der Versuch, ein Objekt in einen schon belegten Bereich zu platzieren, gibt eine Warnung.

Fügt man dem Layout oben noch die Zeilen

```xml
<PlaceObject column="1" row="1">
  <Image file="ocean.pdf" height="4"/>
</PlaceObject>
```

hinzu, ergibt sich folgende Rasterbelegung:

![Doppelt belegtes Raster. Rot markiert sind die Flächen, die sich mehrere Objekte teilen (überlappen)](/img/08-raster3.png)

und eine Warnung:

```
...
PlaceObject: Image in row 1 and column 1, width=4, height=4 (page 1)
Warning: Conflict in grid
...
```

Lässt man die Angaben für Spalte und Zeile weg, sucht sich der Publisher die nächste freie Position selbsttätig.

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Trace grid="yes"/>

  <Record element="data">
    <PlaceObject>
      <Image width="4" file="_samplea.pdf"/>
    </PlaceObject>
    <PlaceObject>
      <Image width="4" file="_sampleb.pdf"/>
    </PlaceObject>
  </Record>
</Layout>
```

![Objekte suchen sich automatisch den nächsten freien Platz, sofern nichts anderes angegeben wird.](/img/twoimages.png)

{{< callout >}}
Absolut platzierte Objekte belegen in der Voreinstellung keine Flächen im Raster. In dem Fall ist `allocate="no"` gesetzt. Mit `allocate="yes"` kann das Verhalten den im Raster platzierten Objekten gleich gesetzt werden.
{{< /callout >}}

## Eigene Raster in Gruppen

Es folgt ein Beispiel für ein vom globalen Raster abweichendes Raster innerhalb einer Gruppe.
Ohne die explizite `<Grid ... />`-Angabe wird das Raster der Seite genommen.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <SetGrid nx="4" ny="4"/>
  <Trace grid="yes" gridallocation="yes" objects="yes"/>

  <Record element="data">
    <Group name="table">
      <Grid width="1cm" height="12pt"/>
      <Contents>
        <PlaceObject>
          <Table width="4" stretch="max">
            <Tr>
              <Td><Paragraph><Value>Cell 1/1</Value></Paragraph></Td>
              <Td><Paragraph><Value>Cell 2/1</Value></Paragraph></Td>
            </Tr>
            <Tr>
              <Td><Paragraph><Value>Cell 1/2</Value></Paragraph></Td>
              <Td><Paragraph><Value>Cell 2/2</Value></Paragraph></Td>
            </Tr>
          </Table>
        </PlaceObject>
        <PlaceObject row="4" column="2">
          <Image file="ocean.pdf" width="3"/>
        </PlaceObject>
      </Contents>
    </Group>

    <PlaceObject groupname="table"/>
  </Record>
</Layout>
```
{{% codecaption %}}Die Gruppe hat ein eigenes Raster, das vom Seitenraster unabhängig ist.{{% /codecaption %}}


![Ausschnitt aus einer Seite. Das Raster innerhalb der Gruppe ist deutlich feiner als das grobe Seitenraster.](/img/08-raster4.png)

