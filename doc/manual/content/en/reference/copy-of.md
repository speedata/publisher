---
linktitle: "Copy-of"
weight: 240
type: docs
---

# `Copy-of`


Replace this element by the copy of the selection as an element structure. You can use it to construct more complex data structures.



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../columns"><code>Columns</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../element"><code>Element</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tablefoot"><code>Tablefoot</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../td"><code>Td</code></a>, <a href="../text"><code>Text</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`select` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}))
: The selection (most likely a variable) that is to be copied.






## Example


```xml
<SetVariable variable="myparagraph">
  <Paragraph>
    <Value select="@name"/><Value>, Symbol=</Value><Value select="@symbol"/>
  </Paragraph>
</SetVariable>
<PlaceObject>
  <Textblock>
    <Copy-of select="$myparagraph"/>
  </Textblock>
</PlaceObject>

```

is the same as



```xml
<PlaceObject>
  <Textblock>
    <Paragraph>
      <Value select="@name"/><Value>, Symbol=</Value><Value select="@symbol"/>
    </Paragraph>
  </Textblock>
</PlaceObject>
```

with the exception that the values of `@name` and `@symbol` can be evaluated before the text gets output.





