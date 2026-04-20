---
linktitle: "Section"
weight: 820
type: docs
---

# `Section`
_seit Version 5.3.24_

Gruppiert Layoutanweisungen. Dieses Element hat keinen Einfluss auf die Ausgabe und dient ausschließlich der Organisation der Layoutdatei, z.B. für Code-Faltung im Texteditor.



## Kindelemente

<a href="../addsearchpath"><code>AddSearchpath</code></a>, <a href="../attachfile"><code>AttachFile</code></a>, <a href="../compatibility"><code>Compatibility</code></a>, <a href="../definecolor"><code>DefineColor</code></a>, <a href="../definecolorprofile"><code>DefineColorprofile</code></a>, <a href="../definefontalias"><code>DefineFontalias</code></a>, <a href="../definefontfamily"><code>DefineFontfamily</code></a>, <a href="../definegraphic"><code>DefineGraphic</code></a>, <a href="../definematter"><code>DefineMatter</code></a>, <a href="../definetextformat"><code>DefineTextformat</code></a>, <a href="../function"><code>Function</code></a>, <a href="../hyphenation"><code>Hyphenation</code></a>, <a href="../loadfontfile"><code>LoadFontfile</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../options"><code>Options</code></a>, <a href="../pdfoptions"><code>PDFOptions</code></a>, <a href="../pageformat"><code>Pageformat</code></a>, <a href="../pagetype"><code>Pagetype</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../record"><code>Record</code></a>, <a href="../section"><code>Section</code></a>, <a href="../setgrid"><code>SetGrid</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../structureelement"><code>StructureElement</code></a>, <a href="../stylesheet"><code>Stylesheet</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../trace"><code>Trace</code></a>, <a href="../while"><code>While</code></a>

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`name` (Text)
: Ein Name für diesen Abschnitt. Dient nur zur Dokumentation.






## Beispiel


```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Section name="Schriften und Farben">
    <LoadFontfile name="titel" filename="titel.otf" />
    <DefineFontfamily name="titel" fontsize="14" leading="16">
      <Regular fontface="titel"/>
    </DefineFontfamily>
    <DefineColor name="hervorhebung" value="#cc0000" />
  </Section>

  <Section name="Seiteneinstellungen">
    <Pageformat width="210mm" height="297mm" />
    <SetGrid height="12pt" width="5mm" />
  </Section>

  <Record element="daten">
    <PlaceObject>
      <Textblock>
        <Paragraph><Value>Hallo</Value></Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```



