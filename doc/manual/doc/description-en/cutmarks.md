title: Crop marks
---
Crop marks
==========

With no special settings, the speedata publisher creates a PDF that has
exactly the size of the given pages. If you need to add trim space or
crop marks, you need to set them in the
[Options](../commands-en/options.html):

    <Options
      cutmarks="yes"
      trim="3mm"/>

This instruction creates crop marks that have a length of 1cm and are
3mm from the inner page border apart (TrimBox). The distance is denoted
by the trim parameter above. The trim parameter has a minimum value of
5pt if given.

The generated PDF file always contains the following PDF boxes: the
surrounding box is the *MediaBox*, the given trim is marked by the
*BleedBox* and the page itself is surrounded tightly by the *TrimBox*.
If no trim is given, the *BleedBox* and the *TrimBox* have the same
size. If no crop marks are output, the *MediaBox* is the same as the
*TrimBox*. That way, in neither `cutmarks` are displayed nor `trim` has
a size greater than 0, all three boxes have the same size.

Example
-------

In the following example the crop marks go to the blue line, that has
the dimensions of the trim length. The green line shows the regular page
dimensions (screenshot from Adobe Acrobat).

{{ img . "schnittmarken2.png" }}

See also
--------

[Options](../commands-en/options.html)
