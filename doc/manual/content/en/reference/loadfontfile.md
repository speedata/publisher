---
linktitle: "LoadFontfile"
weight: 530
type: docs
---

# `LoadFontfile`


Load a font file (.otf, .ttf, .pfb) and associate it with an internal name. If a glyph is not found in the font file, an error will be raised (this can be configured via the [`Options`]({{% relref "options" %}}) command). You can specify fallbacks as a child element of Loadfontfile.



## Child elements

<a href="../fallback"><code>Fallback</code></a>

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`features` (text, optional, _since version 3.9.29_)
: A comma separated list of OpenType features, such as `+liga,-kern`



`filename` (text)
: The name (with extension) of the font file.



`marginprotrusion` (0 up to 100, optional)
: The amount of protrusion glyphs like -, . and - stick into the right margin. Defaults to 0. The value is multiplied with 0.001em from the current font, so a setting of 200 allows these characters to stick out of the margin 0.2em.



`mode` (optional, _since version 3.9.29_)
: Set the shaping mode of the font. Defaults to `harfbuzz`.


  - `fontforge`: The old and well tested font handler. Renders western scripts well, but no right-to-left or other complex scripts.
  - `harfbuzz`: The new renderer that will eventually handle all scripts including right-to-left.

`name` (text)
: The internal name of the font file. To be used within [`DefineFontfamily`]({{% relref "definefontfamily" %}}).



`oldstylefigures` (optional)
: Use oldstyle figures if the font includes them. (OpenType feature “onum”)


  - `yes`: Use oldstyle figures.
  - `no`: Use lining figures.

`shrink` (number, optional, _since version 4.19.17_)
: Set the maximum shrinkage factor of the fonts. Default is disabled. Values divided by 10 = percent. For example 20 means shrink by maxium of 2%.



`smallcaps` (optional)
: Use small caps glyphs when the font supplies them.


  - `yes`: Use small caps for this font.
  - `no`: Don't switch to small caps (default).

`space` (0 up to 100, optional)
: The natural width between words. Can be stretched by 30% and shrunk by 10%. Defaults to 25. The value is a percentile of the font size.



`step` (number, optional, _since version 4.19.17_)
: Set the step values for shrinkage / stretching. Value divided by 10 is step in percentage. For example: a value of 20 means increase / decrease size in 2% steps. Default 10.



`stretch` (number, optional, _since version 4.19.17_)
: Set the maximum stretch factor of the fonts. Default is disabled. Values divided by 10 = percent. For example 20 means stretch by maxium of 2%.






## Example




## Info


The fonts are optionally taken from the local search path. On Windows the path `%WINDIR%\Fonts` (usually `C:\Windows\Fonts`) and on Mac OS X the paths `/Library/Fonts` and `/System/Library/Fonts` can be used as fallbacks for fonts. This can be configured with the setting `fontpath`.




