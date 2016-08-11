title: Handbuch Publisher
---
Einbinden von Schriftdateien
============================

Formate
-------

Der speedata Publisher kann Schriftdateien in den Formaten

-   PostScript Type1 (`.afm`, `.pfb`)
-   OpenType (`.otf`)
-   TrueType (`.ttf`)

verabeiten.

Vorgehensweise
--------------

Dazu muss im Layoutregelwerk erstens der Name der Schriftdatei mit einem
internen Namen verbunden werden. Zweitens muss eine Schriftfamilie
definiert werden, die mehrere Schriftdateien zu einer Familie gruppiert
(Normal, Fett, Kursiv, Fettkursiv). Der erste Schritt wird mit dem
Element [LoadFontfile](../commands-de/loadfontfile.html) gemacht:

    <LoadFontfile name="Helvetica" filename="texgyreheros-regular.otf" />
    <LoadFontfile name="Helvetica Fett" filename="texgyreheros-bold.otf" />
    <LoadFontfile name="Helvetica Kursiv" filename="texgyreheros-italic.otf" />
    <LoadFontfile name="Helvetica Fett Kursiv" filename="texgyreheros-bolditalic.otf" />

Mit diesen Anweisungen sind die Schriftdateien unter den Namen
`Helvetica`, `Helvetica Fett` u.s.w ansprechbar. Das wird dann im
zweiten Schritt mit
[DefineFontfamily](../commands-de/definefontfamily.html) gemacht:

    <DefineFontfamily name="Überschrift" fontsize="12" leading="14">
      <Regular fontface="Helvetica"/>
      <Bold fontface="Helvetica Fett"/>
      <Italic fontface="Helvetica Kursiv"/>
      <BoldItalic fontface="Helvetica Fett Kursiv"/>
    </DefineFontfamily>

Hier wird die Schriftfamilie `Überschrift` aus den vier oben definierten
Schriftdateien zusammengesetzt.

Tipp
----

Die `LoadFontfile`- Anweisungen lassen sich mithilfe der
Befehlszeile leicht erzeugen. Dazu muss der Publisher mit folgenden
Anweisungen aufgerufen werden:

    sp --xml [--extra-dir=...] list-fonts

Die Ausgabe enthält alle Schriftdateien, die im angegebenen Verzeichnis
zu finden sind. Der Wert im Attribut `name` wird mit dem PostScript
Namen der Schriftart vorbelegt, sie kann im Layoutregelwerk später
geändert werden.
