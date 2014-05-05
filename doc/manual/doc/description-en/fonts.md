title: speedata Publisher manual
---
Font inclusion
==============

Formats
-------

The speedata Publisher can use fonts in the followig formats:

-   PostScript Type1 (`.afm`, `.pfb`)
-   OpenType (`.otf`)
-   TrueType (`.ttf`)

How to include a font
---------------------

In the layout rules the name of the font file must be connected to an
internal name. This internal name is then used in the command
[DefineFontfamily](../commands-en/definefontfamily.html) which groups up
to four fonts in a *family* (regular, bold, italic and bolditalic). The
first step is accomplished with
[LoadFontfile](../commands-en/loadfontfile.html):

    <LoadFontfile name="Helvetica" filename="helvetica-regular.otf" />
    <LoadFontfile name="Helvetica Bold" filename="helvetica-bold.otf" />
    <LoadFontfile name="Helvetica Italic" filename="helvetica-italic.otf" />
    <LoadFontfile name="Helvetica BoldItalic" filename="helvetica-bolditalic.otf" />

After executing these commands, the font files are known as `Helvetica`,
`Helvetica Bold` etc. In the second step they are used by the command
[DefineFontfamily](../commands-en/definefontfamily.html):

    <DefineFontfamily name="heading" fontsize="12" leading="14">
      <Regular fontface="Helvetica"/>
      <Bold fontface="Helvetica Bold"/>
      <Italic fontface="Helvetica Italic"/>
      <BoldItalic fontface="Helvetica BoldItalic"/>
    </DefineFontfamily>

The font family `heading` is composed by the four given font files. Now
you can use the font family in commands such as
[Textblock](../commands-en/textblock.html) or
[Table](../commands-en/table.html).

Note
----

The `LoadFontfile` instructions can be auto generated on the command
line. You need to run the `sp` program with the command `list-fonts`,
such as

    sp --xml [--extra-dir=...] list-fonts

The output contains all font files that are found in the current
directory (and its subdirectories). Additional directories can be
supplied by the shown command line option `--extra-dir=<dirname>`. The
value for the `name` attribute in the `LoadFontfile` command defaults to
the postscript name of the font but can be changed to any other value.
