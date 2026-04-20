---
linktitle: "Include"
weight: 460
type: docs
---

# `Include`


Toplevel element for included layout files.



## Child elements

<a href="../definecolor"><code>DefineColor</code></a>, <a href="../definefontalias"><code>DefineFontalias</code></a>, <a href="../definefontfamily"><code>DefineFontfamily</code></a>, <a href="../definetextformat"><code>DefineTextformat</code></a>, <a href="../hyphenation"><code>Hyphenation</code></a>, <a href="../loadfontfile"><code>LoadFontfile</code></a>, <a href="../options"><code>Options</code></a>, <a href="../pageformat"><code>Pageformat</code></a>, <a href="../pagetype"><code>Pagetype</code></a>, <a href="../record"><code>Record</code></a>, <a href="../section"><code>Section</code></a>, <a href="../setgrid"><code>SetGrid</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../stylesheet"><code>Stylesheet</code></a>, <a href="../switch"><code>Switch</code></a>

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`xml:base` (optional)
: (not intended to be used, for error-free validation purpose only)






## Example


The main file:



```xml
<?xml version="1.0" encoding="UTF-8"?>
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en"
  xmlns:xi="http://www.w3.org/2001/XInclude">

  <xi:include href="sublayout.xml" />

  <Record element="data">
    <PlaceObject background="full" background-color="green">
      <Textblock>
        <Paragraph><Value>Hello world</Value></Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>

</Layout>

```

and the file `sublayout.xml`:



```xml
<?xml version="1.0" encoding="UTF-8"?>
<Include xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <DefineColor name="green" value="#0f0"/>
  <DefineColor name="gray" value="#ddd"/>

</Include>

```



## Info


This command is obsolete. Use [`Layout`]({{% relref "layout" %}}) instead.




