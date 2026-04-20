---
linktitle: "Text"
weight: 980
type: docs
---

# `Text`


Erzeugt einen Text, der über die Grenzen von Positionierungsrahmen umbrechen kann. Wird mit [`Output`]({{% relref "output" %}}) benutzt.



## Kindelemente

<a href="../bookmark"><code>Bookmark</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../image"><code>Image</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../ol"><code>Ol</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../ul"><code>Ul</code></a>, <a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../output"><code>Output</code></a>

## Attribute


`color` (Text, optional)
: Name der Farbe im Textblock.



`fontfamily` (Text, optional)
: Name der Schriftfamilie, die benutzt werden soll. Voreinstellung ist `text`



`textformat` (Text, optional)
: Name des zu benutzenden Textformats. Wird kein Textformat angegeben, nimmt das System das Textformat `text`.






## Beispiel


```xml
<Pagetype name="seite" test="true()">
  <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
  <PositioningArea name="text">
    <PositioningFrame width="4" height="10" row="1" column="1"/>
    <PositioningFrame width="4" height="10" row="1" column="6"/>
  </PositioningArea>
</Pagetype>
<Record element="data">
  <Output area="text">
    <Text>
      <Paragraph>
        <Value select="string(.)"/>
      </Paragraph>
    </Text>
  </Output>
</Record>

```



