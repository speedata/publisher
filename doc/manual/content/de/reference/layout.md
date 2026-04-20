---
linktitle: "Layout"
weight: 500
type: docs
---

# `Layout`


Das [`Layout`]({{% relref "layout" %}})-Element ist das Wurzelelement im Layoutregelwerk.



## Kindelemente

<a href="../addsearchpath"><code>AddSearchpath</code></a>, <a href="../attachfile"><code>AttachFile</code></a>, <a href="../compatibility"><code>Compatibility</code></a>, <a href="../definecolor"><code>DefineColor</code></a>, <a href="../definecolorprofile"><code>DefineColorprofile</code></a>, <a href="../definefontalias"><code>DefineFontalias</code></a>, <a href="../definefontfamily"><code>DefineFontfamily</code></a>, <a href="../definegraphic"><code>DefineGraphic</code></a>, <a href="../definematter"><code>DefineMatter</code></a>, <a href="../definetextformat"><code>DefineTextformat</code></a>, <a href="../function"><code>Function</code></a>, <a href="../hyphenation"><code>Hyphenation</code></a>, <a href="../loadfontfile"><code>LoadFontfile</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../options"><code>Options</code></a>, <a href="../pdfoptions"><code>PDFOptions</code></a>, <a href="../pageformat"><code>Pageformat</code></a>, <a href="../pagetype"><code>Pagetype</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../record"><code>Record</code></a>, <a href="../section"><code>Section</code></a>, <a href="../setgrid"><code>SetGrid</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../structureelement"><code>StructureElement</code></a>, <a href="../stylesheet"><code>Stylesheet</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../trace"><code>Trace</code></a>, <a href="../while"><code>While</code></a>

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`name` (Text, optional)
: Name des Layouts. Hat keinen Einfluss auf das Layout.



`require` (Text, optional, _seit Version 4.15.10_)
: Kommaseparierte Liste mit erforderlichen Features. Erlaubt sind `luxor`/`lxpath` und `harfbuzz`/`fontforge`



`version` (Zahl, optional)
: Gibt die minimale Version des Publishers an. Format: 1.6.13. Die letzten Ziffern können weggelassen werden. Falls die erste oder die zweite Ziffer der Versionsangabe unterschiedlich ist, wird eine Warnung ausgegeben.






## Beispiel


Nachfolgend ein vollständiges Beispiel für ein Layoutregelwerk. Die erste Datei ist eine Datendatei und wird unter dem Namen `data.xml` gespeichert. Das zweite ist die eigentliche Layoutdatei (`layout.xml`).



```xml
<root>
  <elt gruß="Hallo Welt!" />
</root>
```

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Options mainlanguage="German"/>

  <Record element="root">
    <ProcessNode select="elt"/>
  </Record>

  <Record element="elt">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <Value select="@gruß"></Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```



