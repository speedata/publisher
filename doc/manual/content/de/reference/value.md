---
linktitle: "Value"
weight: 1080
type: docs
---

# `Value`


Beinhaltet einen Textinhalt, der an das umgebende Element übergeben wird.



## Kindelemente

(keine)

## Elternelemente

<a href="../a"><code>A</code></a>, <a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../color"><code>Color</code></a>, <a href="../columns"><code>Columns</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../element"><code>Element</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../i"><code>I</code></a>, <a href="../image"><code>Image</code></a>, <a href="../initial"><code>Initial</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../span"><code>Span</code></a>, <a href="../sub"><code>Sub</code></a>, <a href="../sup"><code>Sup</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tablefoot"><code>Tablefoot</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../td"><code>Td</code></a>, <a href="../text"><code>Text</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}), optional)
: Wert, der zum umgebenden Element übergeben wird.





## Bemerkungen

Der Inhalt kann entweder als XPath-Ausdruck im Attribut select oder als Elementinhalt angegeben werden.

Innenliegende Br-Tags werden als Zeilenumbruch interpretiert.




## Beispiel


```xml
<Textblock>
  <Paragraph>
    <Value select="@name"/><Value>, Symbol=</Value><Value select="@symbol" />
  </Paragraph>
</Textblock>
```



