---
linktitle: "Layout"
weight: 500
type: docs
---

# `Layout`


This command is the root element in the Layout instructions.



## Child elements

<a href="../addsearchpath"><code>AddSearchpath</code></a>, <a href="../attachfile"><code>AttachFile</code></a>, <a href="../compatibility"><code>Compatibility</code></a>, <a href="../definecolor"><code>DefineColor</code></a>, <a href="../definecolorprofile"><code>DefineColorprofile</code></a>, <a href="../definefontalias"><code>DefineFontalias</code></a>, <a href="../definefontfamily"><code>DefineFontfamily</code></a>, <a href="../definegraphic"><code>DefineGraphic</code></a>, <a href="../definematter"><code>DefineMatter</code></a>, <a href="../definetextformat"><code>DefineTextformat</code></a>, <a href="../function"><code>Function</code></a>, <a href="../hyphenation"><code>Hyphenation</code></a>, <a href="../loadfontfile"><code>LoadFontfile</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../options"><code>Options</code></a>, <a href="../pdfoptions"><code>PDFOptions</code></a>, <a href="../pageformat"><code>Pageformat</code></a>, <a href="../pagetype"><code>Pagetype</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../record"><code>Record</code></a>, <a href="../section"><code>Section</code></a>, <a href="../setgrid"><code>SetGrid</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../structureelement"><code>StructureElement</code></a>, <a href="../stylesheet"><code>Stylesheet</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../trace"><code>Trace</code></a>, <a href="../while"><code>While</code></a>

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`name` (text, optional)
: A name for the layout. Optional, without any influence on the layout itself.



`require` (text, optional, _since version 4.15.10_)
: A comma separated list of required default features. Currently supported features are `luxor`/`lxpath` and `harfbuzz`/`fontforge`.



`version` (number, optional)
: Minimum publisher version required. If major or minor version differ, give a warning. Format: 1.6.12 (revision number can be left out).






## Example


This is a complete example for a layout rule set. The first part is the data file (save as `data.xml`) and the second the layout instructions (`layout.xml`).



```xml
<root>
  <elt greeting="Hello world!" />
</root>
```

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Options mainlanguage="English (USA)"/>

  <Record element="root">
    <ProcessNode select="elt"/>
  </Record>

  <Record element="elt">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value select="@greeting"></Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```



