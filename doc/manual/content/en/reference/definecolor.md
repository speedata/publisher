---
linktitle: "DefineColor"
weight: 250
type: docs
---

# `DefineColor`


Colors defined with DefineColors can be referenced later by their name.



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`alpha` (number, optional, _since version 4.3.15_)
: Set the opacity of the color. (0-100/255, where 0 is invisible)



`b` (0 to 100 or 0 to 255, optional)
: Blue part with rgb (0-100) or RGB (0-255).



`c` (0 up to 100, optional)
: Cyan part with cmyk (0-100).



`colorname` (text, optional)
: The name of the spot color if model is “spotcolor”. The name must match the required color name, such as “PANTONE 116 C”.



`g` (0 to 100 or 0 to 255, optional)
: Green part with rgb (0-100) or RGB (0-255) / gray part when using the model gray (0-100).



`k` (0 up to 100, optional)
: Black part with cmyk (0-100).



`m` (0 up to 100, optional)
: Magenta part with cmyk (0-100)



`model` (optional)
: Color model to be used for the color. Currently “rgb”, “cmyk”, “gray” and “spotcolor” are supported.


  - `cmyk`: CMYK (cyan, magenta, yellow, key/black), values between 0 and 100 (100 = full intensity)
  - `rgb`: rgb (red, green, blue), values between 0 and 100, 100 means full intensity
  - `RGB`: rgb (red, green, blue), values between 0 and 255, 255 means full intensity
  - `gray`: Gray (0=black, 100=white)
  - `spotcolor`: Use a PANTONE or HKS color.

`name` (text)
: The name of the color to be defined.



`overprint` (optional)
: Enable overprint for this color.


  - `yes`: Enable overprint for this color.
  - `no`: Disable overprint for this color (default).

`r` (0 to 100 or 0 to 255, optional)
: Red part with rgb (0-100) or RGB (0-255).



`saturation` (number, optional, _since version 4.19.40_)
: The amount of color printed for the spot color (range from 0 = no color to 1 = full color). Defaults to 1



`usecolorprofile` (yes or no, optional, _since version 4.19.33_)
: If yes, make this color definition based on an ICC profile (default).



`value` (text, optional)
: Hex value of the color, such as `#FA5` or `#FFAA55` or `rgb(255,170,85)` or `rgba(255,170,85,1)`.



`y` (0 up to 100, optional)
: Yellow part with cmyk (0-100).






## Example


```xml
<DefineColor name="black" model="cmyk" c="0" m="0" y="0" k="100"/>
<DefineColor name="white" model="rgb" r="100" g="100" b="100"/>
```



## Info


The CSS level 3 colors are predefined in RGB-space. See http://www.w3.org/TR/css3-color/ for the definitions. That means you can use common colors such as `red` or `goldenrod` without using [`DefineColor`]({{% relref "definecolor" %}}).



The predefined colors are: `aliceblue`, `black`, `orange`, `rebeccapurple`, `antiquewhite`, `aqua`, `aquamarine`, `azure`, `beige`, `bisque`, `blanchedalmond`, `blue`, `blueviolet`, `brown`, `burlywood`, `cadetblue`, `chartreuse`, `chocolate`, `coral`, `cornflowerblue`, `cornsilk`, `crimson`, `darkblue`, `darkcyan`, `darkgoldenrod`, `darkgray`, `darkgreen`, `darkgrey`, `darkkhaki`, `darkmagenta`, `darkolivegreen`, `darkorange`, `darkorchid`, `darkred`, `darksalmon`, `darkseagreen`, `darkslateblue`, `darkslategray`, `darkslategrey`, `darkturquoise`, `darkviolet`, `deeppink`, `deepskyblue`, `dimgray`, `dimgrey`, `dodgerblue`, `firebrick`, `floralwhite`, `forestgreen`, `fuchsia`, `gainsboro`, `ghostwhite`, `gold`, `goldenrod`, `gray`, `green`, `greenyellow`, `grey`, `honeydew`, `hotpink`, `indianred`, `indigo`, `ivory`, `khaki`, `lavender`, `lavenderblush`, `lawngreen`, `lemonchiffon`, `lightblue`, `lightcoral`, `lightcyan`, `lightgoldenrodyellow`, `lightgray`, `lightgreen`, `lightgrey`, `lightpink`, `lightsalmon`, `lightseagreen`, `lightskyblue`, `lightslategray`, `lightslategrey`, `lightsteelblue`, `lightyellow`, `lime`, `limegreen`, `linen`, `maroon`, `mediumaquamarine`, `mediumblue`, `mediumorchid`, `mediumpurple`, `mediumseagreen`, `mediumslateblue`, `mediumspringgreen`, `mediumturquoise`, `mediumvioletred`, `midnightblue`, `mintcream`, `mistyrose`, `moccasin`, `navajowhite`, `navy`, `oldlace`, `olive`, `olivedrab`, `orangered`, `orchid`, `palegoldenrod`, `palegreen`, `paleturquoise`, `palevioletred`, `papayawhip`, `peachpuff`, `peru`, `pink`, `plum`, `powderblue`, `purple`, `red`, `rosybrown`, `royalblue`, `saddlebrown`, `salmon`, `sandybrown`, `seagreen`, `seashell`, `sienna`, `silver`, `skyblue`, `slateblue`, `slategray`, `slategrey`, `snow`, `springgreen`, `steelblue`, `tan`, `teal`, `thistle`, `tomato`, `turquoise`, `violet`, `wheat`, `white`, `whitesmoke`, `yellow` and `yellowgreen`




