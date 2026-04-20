---
linktitle: "Group"
weight: 390
type: docs
---

# `Group`


Erzeugt einen virtuellen Bereich, in dem Elemente platziert werden können. Ausgegeben werden die Gruppen anschließend mit [`PlaceObject`]({{% relref "placeobject" %}}).



## Kindelemente

<a href="../contents"><code>Contents</code></a>, <a href="../grid"><code>Grid</code></a>

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`name` (Text)
: Der Name der anzulegenden Gruppe.






## Beispiel


```xml
<Gruppe name="Beispielgruppe">
  <Contents>
    <PlaceObject column="3" row="2">
      <Textblock width="14">
        <Paragraph>
          <Value>Text</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
    <PlaceObject column="2" row="4">
      <Textblock width="14">
        <Paragraph>
          <Value>Nächster Text</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Contents>
</Gruppe>
<PlaceObject groupname="Beispielgruppe" />
```



