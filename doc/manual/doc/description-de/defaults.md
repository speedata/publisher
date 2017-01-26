title: Voreinstellungen im speedata Publisher
---

Voreinstellungen im speedata Publisher
======================================

Der speedata Publisher definiert einige Voreinstellungen, die in der Layout-Datei überschrieben werden können. Sie betreffen die Farben, Schriftarten und Seitenränder.


Schriftarten
------------

Die Distribution enthält die freie Schriftart TeXGyreHeros, einem hochwertigen Helvetica-Klon, in den Varianten Normal, Fett, Kursiv und Fettkursiv. Die Definitionen sind folgende:

    <LoadFontfile name="TeXGyreHeros-Regular" filename="texgyreheros-regular.otf" />
    <LoadFontfile name="TeXGyreHeros-Bold" filename="texgyreheros-bold.otf" />
    <LoadFontfile name="TeXGyreHeros-Italic" filename="texgyreheros-italic.otf" />
    <LoadFontfile name="TeXGyreHeros-BoldItalic" filename="texgyreheros-bolditalic.otf" />

Die dazugehörige Schriftfamilie ist

    <DefineFontfamily name="text" fontsize="10" leading="12">
      <Regular fontface="TeXGyreHeros-Regular"/>
      <Bold fontface="TeXGyreHeros-Bold"/>
      <Italic fontface="TeXGyreHeros-Italic"/>
      <BoldItalic fontface="TeXGyreHeros-BoldItalic"/>
    </DefineFontfamily>

und, da die Schriftfamilie `text` die Voreinstellung für alle Textausgaben ist, ist damit quasi Helvetica 10pt/12pt die Standard-Textschriftart. Durch überschreiben der Schriftfamilie `text` kann eine andere Voreinstellung festgelegt werden.

Die Fontaliase (seit Version 2.7.12) sind auch für die Standardschrift definiert:

* `TeXGyreHeros-Regular`  -> `sans`
* `TeXGyreHeros-Bold`  -> `sans-bold`
* `TeXGyreHeros-Italic`  -> `sans-italic`
* `TeXGyreHeros-BoldItalic`  -> `sans-bolditalic`

Seitenformat
------------

Das voreingestellte Seitenformat ist DIN A4 (210mm × 297mm).

Die Seitenvorlage für alle Seiten ist wie folgt definiert:

    <Pagetype name="Default Page" test="true()">
      <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
    </Pagetype>

Das Seitenraster beträgt 10mm × 10mm.

Farben
------

Die bekannten CSS-Farben sind im RGB-Farbraum definiert. Die Farben `black` und `white` sind im Graustufen-Farbraum definiert.