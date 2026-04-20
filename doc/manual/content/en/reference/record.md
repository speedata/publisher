---
linktitle: "Record"
weight: 770
type: docs
---

# `Record`


Contains the instructions when the publisher processes the element in the data file with the given name. The record matching the root element will be called by the software automatically, all further data handling must be done by the user. Either the attribute `element` or `match` must be given, but not both.



## Child elements

<a href="../addsearchpath"><code>AddSearchpath</code></a>, <a href="../attachfile"><code>AttachFile</code></a>, <a href="../bookmark"><code>Bookmark</code></a>, <a href="../clearpage"><code>ClearPage</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../definecolor"><code>DefineColor</code></a>, <a href="../definefontalias"><code>DefineFontalias</code></a>, <a href="../definefontfamily"><code>DefineFontfamily</code></a>, <a href="../definematter"><code>DefineMatter</code></a>, <a href="../definetextformat"><code>DefineTextformat</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../group"><code>Group</code></a>, <a href="../hyphenation"><code>Hyphenation</code></a>, <a href="../include"><code>Include</code></a>, <a href="../insertpages"><code>InsertPages</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loaddataset"><code>LoadDataset</code></a>, <a href="../loadfontfile"><code>LoadFontfile</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../nextframe"><code>NextFrame</code></a>, <a href="../nextrow"><code>NextRow</code></a>, <a href="../options"><code>Options</code></a>, <a href="../output"><code>Output</code></a>, <a href="../pdfoptions"><code>PDFOptions</code></a>, <a href="../pageformat"><code>Pageformat</code></a>, <a href="../pagetype"><code>Pagetype</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../processnode"><code>ProcessNode</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../setgrid"><code>SetGrid</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../sortsequence"><code>SortSequence</code></a>, <a href="../structureelement"><code>StructureElement</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../until"><code>Until</code></a>, <a href="../value"><code>Value</code></a>, <a href="../while"><code>While</code></a>

## Parent elements

<a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../section"><code>Section</code></a>

## Attributes


`element` (text, optional)
: The name of the element the record matches. Mutually exclusive with `match`.



`match` (text, optional, _since version 5.5.8_)
: An XPath-like pattern to match data elements. Supports simple element names (`foo`), wildcards (`*`), predicates (`item[@type='book']`), parent/child patterns (`catalog/product`), and ancestor patterns (`catalog//item`). A simple element name is equivalent to using `element`. When multiple patterns match, the most specific one wins. Mutually exclusive with `element`. Requires the lxpath XML parser.



`mode` (text, optional)
: Name of the mode that matches the mode in [`ProcessNode`]({{% relref "processnode" %}}).






## Example


```xml
<Record element="url" mode="output">
  <PlaceObject>
    <Textblock>
      <Paragraph>
        <A href="https://www.speedata.de"><Value>website of speedata</Value></A>
      </Paragraph>
    </Textblock>
  </PlaceObject>
</Record>

<!-- Pattern matching examples -->
<Record match="item[@type='book']">
  ...
</Record>

<Record match="catalog/product">
  ...
</Record>

<Record match="*">
  <!-- Fallback for unmatched elements -->
  ...
</Record>

```



