---
linktitle: "Options"
weight: 630
type: docs
---

# `Options`


Set publisher specific options.



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`background-color` (text, optional, _since version 4.19.11_)
: Render colored background behind each page. Defaults to 'white'. State a color name or '-' for no background.



`bleed` (length, optional)
: The amount of bleed. Defaults to 0mm.



`bleedmarks` (optional, _since version 2.3.24_)
: Trim marks will be placed in the PDF. The distance of the marks from the imaginary center is determined by the attribute `trim`, but is at least 5mm. The length of the cut marks is 1cm. The default of this attribute is `no`, that means no trim marks will be displayed. The trim marks show the additional trim distance.


  - `yes`: Show trim marks.
  - `no`: Don't show trim marks (default).

`crop` (yes, no or length, optional, _since version 2.3.21_)
: Crop the pages so that the pdf size of the page is at its minimum. Allowed values are yes, no and a length.



`cutmarks` (optional)
: Cut marks / crop marks will be placed in the PDF. The distance of the marks from the imaginary center is determined by the attribute `trim`, but is at least 5mm. The length of the cut marks is 1cm. The default of this attribute is `no`, that means no cut marks will be displayed.


  - `yes`: Show crop marks.
  - `no`: Don't show crop marks (default).

`defaultarea` (text, optional, _since version 2.7.4_)
: Name of the area that is used as a default for placing text (commands [`Output`]({{% relref "output" %}}) and [`PlaceObject`]({{% relref "placeobject" %}})). Default is `_page`.



`fontexpansion` (optional, _since version 4.19.17_)
: Allow glyph stretching and shrinking. Default is 'yes'.


  - `no`: Do not allow font stretching or shrinking.
  - `some`: Stretching and shrinking is applied after the line break.
  - `yes`: Stretching and shrinking is applied before linebreak, so the line breaking algorithm has more possible break points thus leading to a “better” visual appearance.

`fontshrink` (number, optional, _since version 4.19.17_)
: Set the default maximum shrinkage factor of the fonts. Default is disabled. Values divided by 10 = percent. For example 20 means shrink by maxium of 2%.



`fontstep` (number, optional, _since version 4.19.17_)
: Set the default step values for shrinkage / stretching. Value divided by 10 is step in percentage. For example: a value of 20 means increase / decrease size in 2% steps. Default 10.



`fontstretch` (number, optional, _since version 4.19.17_)
: Set the default maximum stretch factor of the fonts. Default is disabled. Values divided by 10 = percent. For example 20 means stretch by maxium of 2%.



`html` (optional, _since version 5.3.12_)
: Default setting for HTML parsing in paragraphs. Can be overridden locally in [`Paragraph`]({{% relref "paragraph" %}}). Setting this to 'off' can significantly improve typesetting performance when HTML tags like <b> or <i> are not used.


  - `all`: Parse HTML in all paragraphs (default).
  - `inner`: Parse HTML only in child elements of the current data element.
  - `off`: Disable HTML parsing in paragraphs.

`ignoreeol` (optional)
: Ignore newlines in data-xml


  - `yes`: Ignore newlines in data-xml
  - `no`: Respect newlines in data-xml

`imagenotfound` (optional, _since version 2.3.43_)
: When an image is not found: should the publisher raise an error?


  - `warning`: Show a warning
  - `error`: Raise an error (default)

`interaction` (yes or no, optional, _since version 3.9.2_)
: If no, switch off all interaction (hyperlinks).



`mainlanguage` (optional)
: The default language for text (hyphenation and rendering). You can also set the default language on the command line and locally set it at [`Paragraph`]({{% relref "paragraph" %}}) and [`Textblock`]({{% relref "textblock" %}}).



`markdown-extensions` (text, optional, _since version 4.17.11_)
: Set the markdown extensions. Must be a comma seprarated list of one or more of these values: table, strikethrough, linkify, tasklist, gfm, definitionlist, footnote, typographer, cjk.



`mpcolorwarning` (yes or no, optional, _since version 5.1.9_)
: Show a warning if the color name is not compatible with MetaPost.



`namespaces` (optional, _since version 4.19.37_)
: Controls the handling of XML namespaces. The default is 'lax' which ignores all namespaces with [`Record`]({{% relref "record" %}}) and [`ProcessNode`]({{% relref "processnode" %}}).


  - `lax`: This is the default. XML namespaces in the data file are ignored.
  - `strict`: [`Record`]({{% relref "record" %}}) and [`ProcessNode`]({{% relref "processnode" %}}) are namespace sensitive.

`overfull-line` (optional, _since version 4.19.10_)
: Raise a warning or an error if a text line is too wide for a text block.


  - `warning`: Show a warning
  - `error`: Raise an error
  - `ignore`: Ignore this case (default).

`randomseed` (number, optional, _since version 3.9.24_)
: Set the seed for the random number generator (a positive integer).



`reportmissingglyphs` (optional, _since version 3.1.17_)
: Issue an error if glyphs are missing from a font.


  - `yes`: Show error message (default)
  - `no`: Do not show an error message
  - `warning`: Show a warning

`resetmarks` (optional)
: Yes: ignore the marks file from previous run.


  - `yes`: Ignore marks from the previous run.
  - `no`: Use marks from the previous run (default).

`startpage` (number, optional)
: Set the number of the first page.



`tablerulefix` (yes or no, optional, _since version 4.21.3_)
: Re-draw rules in table so they appear on top of the table. This fixes a display bug in Adobe Acrobat when colored backgrounds are used.





## Remarks

Bleed used to be 'trim' in version 2.7.6 and before.




## Example


```xml
<Options
    cutmarks="yes"
    bleed="3mm"/>
```



## Info


The list of languages and the short code known to the system are:



`Ancient Greek` (`grc`), `Armenian` (`hy`), `Bahasa Indonesia` (`id`), `Basque` (`eu`), `Bulgarian` (`bg`), `Catalan` (`ca`), `Chinese` (`zh`), `Croatian` (`hr`), `Czech` (`cs`), `Danish` (`da`), `Dutch` (`nl`), `English` (`en_GB`), `English (Great Britain)` (`en_GB`), `English (USA)` (`en_US`), `Esperanto` (`eo`), `Estonian` (`et`), `Finnish` (`fi`), `French` (`fr`), `Galician` (`gl`), `German` (`de`), `Greek` (`el`), `Gujarati` (`gu`), `Hindi` (`hi`), `Hungarian` (`hu`), `Icelandic` (`is`), `Irish` (`ga`), `Italian` (`it`), `Kannada` (`kn`), `Kurmanji` (`ku`), `Latvian` (`lv`), `Lithuanian` (`lt`), `Malayalam` (`ml`), `Norwegian Bokmål` (`nb`), `Norwegian Nynorsk` (`nn`), `Other` (`--`), `Polish` (`pl`), `Portuguese` (`pt`), `Romanian` (`ro`), `Russian` (`ru`), `Sanskrit` (`sa`), `Serbian` (`sr`), `Serbian (cyrillic)` (`sc`), `Slovak` (`sk`), `Slovenian` (`sl`), `Spanish` (`es`), `Swedish` (`sv`), `Turkish` (`tr`), `Ukrainian` (`uk`), `Welsh` (`cy`)




