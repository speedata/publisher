---
linktitle: "DefineFontfamily"
weight: 280
type: docs
---

# `DefineFontfamily`


Das Element [`DefineFontfamily`]({{% relref "definefontfamily" %}}) definiert eine Schriftfamilie, auf in den Elementen [`Paragraph`]({{% relref "paragraph" %}}), [`Textblock`]({{% relref "textblock" %}}), [`Fontface`]({{% relref "fontface" %}}) und [`Table`]({{% relref "table" %}}) mit dem Attribut `fontfamily` zugegriffen werden kann.



## Kindelemente

<a href="../bold"><code>Bold</code></a>, <a href="../bolditalic"><code>BoldItalic</code></a>, <a href="../italic"><code>Italic</code></a>, <a href="../regular"><code>Regular</code></a>

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`fontsize` (Zahl)
: Schriftgröße. Ohne Einheit wird DTP Punkte angenommen.



`leading` (Zahl)
: Abstand zwischen zwei Grundlinien. Ohne Einheit wird DTP Punkte erwartet.



`name` (Text)
: Interner Name, unter dem die Schriftfamilie später angesprochen wird.



`scriptsize` (Längenangabe, optional, _seit Version 4.19.31_)
: Schriftgröße der kleingestellten Zeichen. Voreingestellt sind 80% der Schriftgröße.



`subshift` (Längenangabe, optional, _seit Version 4.19.31_)
: Verschiebung der tiefgestellten Zeichen. 0pt ist auf der Grundlinie, positive Werte verschieben nach unten. Voreinstellung ist 30% der Schriftgröße.



`supershift` (Längenangabe, optional, _seit Version 4.19.31_)
: Verschiebung der hochgestellten Zeichen. 0pt ist auf der Grundlinie, positive Werte verschieben nach unten. Voreinstellung ist 30% der Schriftgröße.





## Bemerkungen

Wird keine Schriftart angegeben, dann wird auf die Schriftfamilie text (kleines ‘t’) zurückgegriffen.

Die Schnitte Fett, Kursiv und FettKursiv müssen nur dann angegeben werden, wenn sie auch benutzt werden. Es wird aber empfohlen, diese anzugeben, damit nicht unbemerkt auf die Standardschriftart umgeschaltet wird.




## Beispiel


```xml
<DefineFontfamily name="Helvetica" fontsize="12" leading="14">
  <Regular fontface="Helvetica Normal"/>
  <Bold fontface="Helvetica Fett"/>
  <Italic fontface="Helvetica Kursiv"/>
  <BoldItalic fontface="Helvetica Fett Kursiv"/>
</DefineFontfamily>
```

Anschließend kann im Text auf diese Schriftfamilie zugegriffen werden:



```xml
<Textblock fontfamily="Helvetica">
  <Paragraph>
   ...
```



