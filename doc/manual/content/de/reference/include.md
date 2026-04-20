---
linktitle: "Include"
weight: 460
type: docs
---

# `Include`


Toplevel Element für eingebundene Layoutdateien.



## Kindelemente

<a href="../definecolor"><code>DefineColor</code></a>, <a href="../definefontalias"><code>DefineFontalias</code></a>, <a href="../definefontfamily"><code>DefineFontfamily</code></a>, <a href="../definetextformat"><code>DefineTextformat</code></a>, <a href="../hyphenation"><code>Hyphenation</code></a>, <a href="../loadfontfile"><code>LoadFontfile</code></a>, <a href="../options"><code>Options</code></a>, <a href="../pageformat"><code>Pageformat</code></a>, <a href="../pagetype"><code>Pagetype</code></a>, <a href="../record"><code>Record</code></a>, <a href="../section"><code>Section</code></a>, <a href="../setgrid"><code>SetGrid</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../stylesheet"><code>Stylesheet</code></a>, <a href="../switch"><code>Switch</code></a>

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`xml:base` (optional)
: (nicht zur Benutzung gedacht, ist nur eingebaut, um Validierungsfehler zu vermeiden)






## Beispiel


Die Hauptdatei



```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
       xmlns:xi="http://www.w3.org/2001/XInclude">
 <xi:include href="fontdefinitionen.xml" />
 ...
```

Die Datei `fontdefinitionen.xml`:



```xml
<Include xmlns="urn:speedata.de:2009/publisher/en">
  <LoadFontfile name="Helvetica"
                    filename="texgyreheros-regular.otf"/>
  <LoadFontfile name="Helvetica Fett"
                    filename="texgyreheros-bold.otf"/>
  <LoadFontfile name="Helvetica Kursiv"
                    filename="texgyreheros-italic.otf"/>
  <LoadFontfile name="Helvetica Fett Kursiv"
                    filename="texgyreheros-bolditalic.otf"/>
</Include>
```



## Hinweis


Dieser Befehl ist obsolete. Benutze [`Layout`]({{% relref "layout" %}}) anstelle von Include.




