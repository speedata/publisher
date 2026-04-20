---
linktitle: "DefineColor"
weight: 250
type: docs
---

# `DefineColor`


Definiert Farben, die später im Layout benutzt werden können



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`alpha` (Zahl, optional, _seit Version 4.3.15_)
: Setze die Farbintensität (Deckung) im Bereich von 0-100 bzw. bei RGB von 0-255. 0 bedeutet unsichtbar.



`b` (0 bis 100 bzw. 0 bis 255, optional)
: Blau Anteil bei rgb (0-100) oder RGB (0-255).



`c` (0 bis 100, optional)
: Cyan Anteil bei cmyk (0-100).



`colorname` (Text, optional)
: Der Name der Sonderfarbe wenn das Modell auf »spotcolor« eingestellt ist. Der muss den offiziellen Namen tragen, wie z.B. »PANTONE 116 C«.



`g` (0 bis 100 bzw. 0 bis 255, optional)
: Grün Anteil bei rgb (0-100) oder RGB (0-255) bzw. Grauanteil beim Farbmodell gray (0-100).



`k` (0 bis 100, optional)
: Schwarz (key) Anteil bei cmyk (0-100).



`m` (0 bis 100, optional)
: Magenta Anteil bei cmyk (0-100)



`model` (optional)
: Das Farbmodell, das benutzt werden soll. Derzeit werden »rgb«, »cmyk«, »gray« und »spotcolor« unterstützt.


  - `cmyk`: CMYK (Türkis, Magenta, Gelb und Schwarz), Werte zwischen 0 und 100 (100 = volle Intensität)
  - `rgb`: RGB (Rot, Grün, Blau), Werte zwischen 0 und 100, 100 bedeutet volle Intensität
  - `RGB`: RGB (Rot, Grün, Blau), Werte zwischen 0 und 255, 255 bedeutet volle Intensität
  - `gray`: Graustufen (0=Schwarz,100=Weiß)
  - `spotcolor`: Eine PANTONE oder HKS Farbe.

`name` (Text)
: Name der Farbe, die definiert wird.



`overprint` (optional)
: Überdrucken für diese Farbe anschalten


  - `yes`: Überdrucken für diese Farbe anschalten.
  - `no`: Überdrucken für diese Farbe ausschalten (Voreinstellung).

`r` (0 bis 100 bzw. 0 bis 255, optional)
: Rot Anteil bei rgb (0-100) oder RGB (0-255).



`saturation` (Zahl, optional, _seit Version 4.19.40_)
: Die Farbmenge für Sonderfarben. Bereich von 0 (keine Farbe) bis 1 (voller Farbauftrag). Voreinstellung ist 1.



`usecolorprofile` (yes oder no, optional, _seit Version 4.19.33_)
: Wenn 'yes', dann wird für die Farbe ein Farbprofil eingebettet. (Voreinstellung)



`value` (Text, optional)
: Der Hexwert der Farbe, wie beispielsweise `#FA5` oder `#FFAA55` oder `rgb(255,170,85)` oder `rgba(255,170,85,1)`.



`y` (0 bis 100, optional)
: Gelb Anteil bei cmyk (0-100).






## Beispiel


```xml
<DefineColor name="Schwarz" model="cmyk" c="0" m="0" y="0" k="100"/>
<DefineColor name="Weiß" model="rgb" r="100" g="100" b="100"/>
```



## Hinweis


Die Farben aus CSS Level 3 sind vordefinert im RGB-Farbraum. Siehe http://www.w3.org/TR/css3-color/ für die Definitionen. Damit kann man häufige Farben wie `red` oder `goldenrod` benutzen, ohne sie vorher mit [`DefineColor`]({{% relref "definecolor" %}}) zu definieren.



Die vordefinierten Farben sind `aliceblue`, `black`, `orange`, `rebeccapurple`, `antiquewhite`, `aqua`, `aquamarine`, `azure`, `beige`, `bisque`, `blanchedalmond`, `blue`, `blueviolet`, `brown`, `burlywood`, `cadetblue`, `chartreuse`, `chocolate`, `coral`, `cornflowerblue`, `cornsilk`, `crimson`, `darkblue`, `darkcyan`, `darkgoldenrod`, `darkgray`, `darkgreen`, `darkgrey`, `darkkhaki`, `darkmagenta`, `darkolivegreen`, `darkorange`, `darkorchid`, `darkred`, `darksalmon`, `darkseagreen`, `darkslateblue`, `darkslategray`, `darkslategrey`, `darkturquoise`, `darkviolet`, `deeppink`, `deepskyblue`, `dimgray`, `dimgrey`, `dodgerblue`, `firebrick`, `floralwhite`, `forestgreen`, `fuchsia`, `gainsboro`, `ghostwhite`, `gold`, `goldenrod`, `gray`, `green`, `greenyellow`, `grey`, `honeydew`, `hotpink`, `indianred`, `indigo`, `ivory`, `khaki`, `lavender`, `lavenderblush`, `lawngreen`, `lemonchiffon`, `lightblue`, `lightcoral`, `lightcyan`, `lightgoldenrodyellow`, `lightgray`, `lightgreen`, `lightgrey`, `lightpink`, `lightsalmon`, `lightseagreen`, `lightskyblue`, `lightslategray`, `lightslategrey`, `lightsteelblue`, `lightyellow`, `lime`, `limegreen`, `linen`, `maroon`, `mediumaquamarine`, `mediumblue`, `mediumorchid`, `mediumpurple`, `mediumseagreen`, `mediumslateblue`, `mediumspringgreen`, `mediumturquoise`, `mediumvioletred`, `midnightblue`, `mintcream`, `mistyrose`, `moccasin`, `navajowhite`, `navy`, `oldlace`, `olive`, `olivedrab`, `orangered`, `orchid`, `palegoldenrod`, `palegreen`, `paleturquoise`, `palevioletred`, `papayawhip`, `peachpuff`, `peru`, `pink`, `plum`, `powderblue`, `purple`, `red`, `rosybrown`, `royalblue`, `saddlebrown`, `salmon`, `sandybrown`, `seagreen`, `seashell`, `sienna`, `silver`, `skyblue`, `slateblue`, `slategray`, `slategrey`, `snow`, `springgreen`, `steelblue`, `tan`, `teal`, `thistle`, `tomato`, `turquoise`, `violet`, `wheat`, `white`, `whitesmoke`, `yellow` und `yellowgreen`.




