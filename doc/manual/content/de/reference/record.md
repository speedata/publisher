---
linktitle: "Record"
weight: 770
type: docs
---

# `Record`


Enthält die Anweisungen, die bei dem angegebenen Datensatz ausgeführt werden sollen. Der oberste Datensatz (d.h. direkt unterhalb des Wurzelelements) wird vom Publisher aufgerufen, alle nachfolgenden Datensätze müssen über das Element BearbeiteKnoten aufgerufen werden. Es muss entweder das Attribut `element` oder `match` angegeben werden, aber nicht beide gleichzeitig.



## Kindelemente

<a href="../addsearchpath"><code>AddSearchpath</code></a>, <a href="../attachfile"><code>AttachFile</code></a>, <a href="../bookmark"><code>Bookmark</code></a>, <a href="../clearpage"><code>ClearPage</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../definecolor"><code>DefineColor</code></a>, <a href="../definefontalias"><code>DefineFontalias</code></a>, <a href="../definefontfamily"><code>DefineFontfamily</code></a>, <a href="../definematter"><code>DefineMatter</code></a>, <a href="../definetextformat"><code>DefineTextformat</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../group"><code>Group</code></a>, <a href="../hyphenation"><code>Hyphenation</code></a>, <a href="../include"><code>Include</code></a>, <a href="../insertpages"><code>InsertPages</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loaddataset"><code>LoadDataset</code></a>, <a href="../loadfontfile"><code>LoadFontfile</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../nextframe"><code>NextFrame</code></a>, <a href="../nextrow"><code>NextRow</code></a>, <a href="../options"><code>Options</code></a>, <a href="../output"><code>Output</code></a>, <a href="../pdfoptions"><code>PDFOptions</code></a>, <a href="../pageformat"><code>Pageformat</code></a>, <a href="../pagetype"><code>Pagetype</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../processnode"><code>ProcessNode</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../setgrid"><code>SetGrid</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../sortsequence"><code>SortSequence</code></a>, <a href="../structureelement"><code>StructureElement</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../until"><code>Until</code></a>, <a href="../value"><code>Value</code></a>, <a href="../while"><code>While</code></a>

## Elternelemente

<a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../section"><code>Section</code></a>

## Attribute


`element` (Text, optional)
: Der Name des Elements der auf den Datensatz passt. Kann nicht zusammen mit `match` verwendet werden.



`match` (Text, optional, _seit Version 5.5.8_)
: Ein XPath-ähnliches Pattern zum Abgleich von Datenelementen. Unterstützt einfache Elementnamen (`foo`), Wildcards (`*`), Prädikate (`item[@type='book']`), Eltern/Kind-Muster (`catalog/product`) und Vorfahren-Muster (`catalog//item`). Ein einfacher Elementname ist gleichbedeutend mit `element`. Bei mehreren passenden Patterns gewinnt das spezifischste. Kann nicht zusammen mit `element` verwendet werden. Benötigt den lxpath XML-Parser.



`mode` (Text, optional)
: Name des Modus der mit dem in [`ProcessNode`]({{% relref "processnode" %}}) übereinstimmt.






## Beispiel


```xml
<Record element="url" mode="ausgabe">
  <PlaceObject>
    <Textblock>
      <Paragraph>
        <A href="https://www.speedata.de"><Value>Webseite von speedata</Value></A>
      </Paragraph>
    </Textblock>
  </PlaceObject>
</Record>

<!-- Beispiele für Pattern-Matching -->
<Record match="item[@type='book']">
  ...
</Record>

<Record match="catalog/product">
  ...
</Record>

<Record match="*">
  <!-- Fallback für nicht zugeordnete Elemente -->
  ...
</Record>

```



