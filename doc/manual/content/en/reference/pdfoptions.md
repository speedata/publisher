---
linktitle: "PDFOptions"
weight: 670
type: docs
---

# `PDFOptions`
_since version 2.3.39_

Set PDF options like number of copies and such



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>

## Attributes


`author` (text, optional, _since version 3.1.18_)
: Set the author of the document



`colorprofile` (optional, _since version 3.5.7_)
: Set the name of the color profile. Has to be defined with [`DefineColorprofile`]({{% relref "definecolorprofile" %}}).



`creator` (text, optional, _since version 4.9.2_)
: Set the creator application of the document



`displaymode` (optional, _since version 4.11.8_)
: Select the display mode when opening PDF document (mainly with Acrobat).


  - `attachments`: Display the attachment pane.
  - `bookmarks`: Display the bookmarks pane (only works if the PDF document contains at least one bookmark).
  - `fullscreen`: Open the document in fullscreen mode.
  - `none`: Do not display a special pane.
  - `thumbnails`: Display the thumbnail pane.

`dpi` (number, optional, _since version 4.17.10_)
: Set the maximum DPI number for PNG/JPEG images.



`duplex` (optional, _since version 2.3.47_)
: Set viewer preference to one or two page printing. Default: empty.


  - `simplex`: One page per sheet
  - `duplexflipshortedge`: Two pages per sheet and flip on short edge
  - `duplexfliplongedge`: Two pages per sheet and flip on long edge

`format` (optional, _since version 3.5.7_)
: Set the output format.


  - `PDF/X-3`: Set the output to `PDF/X-3`.
  - `PDF/X-4`: Set the output to `PDF/X-4`.
  - `PDF/A-3`: Set the output to `PDF/A-3`.
  - `PDF/UA`: Set the output to `PDF/UA`.

`hyperlinkbordercolor` (text, optional, _since version 4.11.8_)
: Set the border color of hyperlinks when showhyperlinks is set. The default is black. (Renamed from hyperlinksbordercolor.)



`hyperlinkborderwidth` (text, optional, _since version 4.15.6_)
: Set the border width of hyperlinks when showhyperlinks is set. The default is 1pt.



`keywords` (text, optional, _since version 3.1.24_)
: Set the keywords of the document (comma separated list).



`numcopies` (number, optional)
: Set the number of copies. At most 5 are allowed in the PDF specification.



`pagelayout` (optional, _since version 4.15.1_)
: Specify the layout of the pages in Adobe Acrobat.


  - `singlepage`: Display one page at a time.
  - `onecolumn`: Display the pages in one column.
  - `twocolumnleft`: Display the pages in two columns, with odd- numbered pages on the left.
  - `twocolumnright`: Display the pages in two columns, with odd- numbered pages on the right.
  - `twopageleft`: Display the pages two at a time, with odd-numbered pages on the left.
  - `twopageright`: Display the pages two at a time, with odd-numbered pages on the right.

`picktraybypdfsize` (optional, _since version 2.3.46_)
: Activate the check box in the PDF viewer for choosing the paper tray based on the page size.


  - `yes`: Activate checkbox
  - `no`: Deactivate checkbox

`printscaling` (optional, _since version 2.3.46_)
: Should the printer scale the pages?


  - `appdefault`: Use the default from the PDF viewer
  - `none`: No page scaling

`producer` (text, optional, _since version 4.19.3_)
: Set the producer of the document



`showbookmarks` (yes or no, optional, _since version 3.9.8_, deprecated)
: Show bookmarks in the PDF viewer when opening the document. Deprecated - use displaymode instead.



`showhyperlinks` (yes or no, optional, _since version 4.3.15_)
: Show hyperlinks in Adobe Acrobat and perhaps other PDF viewers.



`subject` (text, optional, _since version 3.1.24_)
: Set the subject of the document



`title` (text, optional, _since version 3.1.18_)
: Set the title of the document






## Example


```xml
<PDFOptions numcopies="3"/>
```



