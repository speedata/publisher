---
linktitle: "SortSequence"
weight: 850
type: docs
---

# `SortSequence`


Sortiert eine Liste.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../element"><code>Element</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`criterion` (Text)
: Attributname, nach dem sortiert werden soll.



`numerical` (optional, _seit Version 3.1.21_)
: Sortiere alphabetisch oder numerisch


  - `yes`: Sortiere numerisch
  - `no`: Sortiere alphabetisch (Voreinstellung)

`order` (optional, _seit Version 3.1.22_)
: Wähle die Sortierreihenfolge


  - `ascending`: Benutze aufsteigende Sortierreihenfolge (Voreinstellung)
  - `descending`: Benutze absteigende Sortierreihenfolge

`removeduplicates` (Text, optional)
: Wenn Duplikate gelöscht werden sollen, steht hier das Attribut mit dem Inhalt.



`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}))
: Datensatz, der sortiert werden soll






## Beispiel


Daten:



```xml
<data>
  <elt value="one"/>
  <elt value="two"/>
  <elt value="three"/>
</data>

```

Layout:



```xml
<Record element="data">
  <SetVariable variable="unsorted" select="*"/>
  <SetVariable variable="sorted">
    <SortSequence select="$unsorted" criterion="value"/>
  </SetVariable>
  <PlaceObject>
    <Textblock>
      <ForAll select="$sorted">
        <Paragraph><Value select="@value"/></Paragraph>
      </ForAll>
    </Textblock>
  </PlaceObject>
</Record>
```



