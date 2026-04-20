---
linktitle: "Textblock"
weight: 990
type: docs
---

# `Textblock`


Erzeugt einen rechteckigen Bereich mit Text.



## Kindelemente

<a href="../bookmark"><code>Bookmark</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../html"><code>HTML</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../mark"><code>Mark</code></a>, <a href="../ol"><code>Ol</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../ul"><code>Ul</code></a>, <a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../clip"><code>Clip</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../td"><code>Td</code></a>, <a href="../transformation"><code>Transformation</code></a>

## Attribute


`angle` (Zahl, optional)
: Winkel (Drehrichtung gegen den Uhrzeigersinn), um der der Text gedreht wird. Die Spalte und die Zeile, in der der Text ausgegeben wird, bleibt gleich, die Breite und die Höhe des Textes ändert sich gegenüber dem ursprünglichen Text.



`color` (Text, optional)
: Name der Farbe im Textblock.



`columndistance` (Zahl oder Längenangabe, optional)
: Abstand zwischen zwei Spalten. Voreinstellung: 3mm.



`columns` (Zahl, optional)
: Anzahl der Spalten in dem Textblock. Mehrere Spalten nur für normalen Text benutzen.



`fontfamily` (Text, optional)
: Name der Schriftfamilie, die benutzt werden soll.



`language` (optional, _seit Version 4.1.1_)
: Setze die Sprache für Silbentrennung und Darstellung.



`minheight` (Zahl oder Längenangabe, optional, _seit Version 2.3.28_)
: Die minimale Höhe des Textblocks als Längenangabe oder als Maßeinheit.



`textformat` (Text, optional)
: Name des zu benutzenden Textformats. Wird kein Textformat angegeben, nimmt das System das Textformat `text`.



`width` (Zahl, optional)
: Anzahl der Spalten, die der Text einnehmen soll. Wenn das Attribut nicht angegeben wird, so bestimmt das umliegende Element die Breite.





## Bemerkungen

Durch die Angabe eines Textformats wird das Aussehen der Absätze beeinflusst. Textformate müssen vorher mit [`DefineTextformat`]({{% relref "definetextformat" %}}) festgelegt werden.
        Wenn kein Textformat angegeben wird, nimmt das System das Textformat `text`.

Vorsichtig sein bei Mehrspaltensatz. Dieser darf nur für einfache Texte benutzt werden, nicht für Aufzählungslisten oder ähnliches.




## Beispiel


```xml
<PlaceObject>
  <Textblock width="10" angle="-20">
    <Paragraph>
      <B><Value>Text in Fett</Value></B>
    </Paragraph>
  </Textblock>
</PlaceObject>
```



