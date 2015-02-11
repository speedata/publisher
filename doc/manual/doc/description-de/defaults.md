title: Voreinstellungen im speedata Publisher
---

Voreinstellungen im speedata Publisher
======================================

Der speedata Publisher definiert einige Voreinstellungen, die in der Layout-Datei überschrieben werden können. Sie betreffen die Farben, Schriftarten und Seitenränder.


Schriftarten
------------

Die Distribution enthält die freie Schriftart TeXGyreHeros, einem hochwertigen Helvetica-Klon, in den Varianten Normal, Fett, Kursiv und Fettkursiv. Die Definitionen sind folgende:

    <LadeSchriftdatei name="TeXGyreHeros-Regular" dateiname="texgyreheros-regular.otf" />
    <LadeSchriftdatei name="TeXGyreHeros-Bold" dateiname="texgyreheros-bold.otf" />
    <LadeSchriftdatei name="TeXGyreHeros-Italic" dateiname="texgyreheros-italic.otf" />
    <LadeSchriftdatei name="TeXGyreHeros-BoldItalic" dateiname="texgyreheros-bolditalic.otf" />

Die dazugehörige Schriftfamilie ist

    <DefiniereSchriftfamilie name="text" schriftgröße="10" zeilenabstand="12">
      <Normal schriftart="TeXGyreHeros-Regular"/>
      <Fett schriftart="TeXGyreHeros-Bold"/>
      <Kursiv schriftart="TeXGyreHeros-Italic"/>
      <FettKursiv schriftart="TeXGyreHeros-BoldItalic"/>
    </DefiniereSchriftfamilie>

und, da die Schriftfamilie `text` die Voreinstellung für alle Textausgaben ist, ist damit quasi Helvetica 10pt/12pt die Standard-Textschriftart. Durch überschreiben der Schriftfamilie `text` kann eine andere Voreinstellung festgelegt werden.

Seitenformat
------------

Das voreingestellte Seitenformat ist DIN A4 (210mm × 297mm).

Die Seitevorlage für alle Seiten ist wie folgt definiert:

    <Seitentyp name="Default Page" bedingung="true()">
      <Rand links="1cm" rechts="1cm" oben="1cm" unten="1cm"/>
    </Seitentyp>

Das Seitenraster beträgt 10mm × 10mm.

Farben
------

Die bekannten CSS-Farben sind im RGB-Farbraum definiert. Die Farben `black` und `white` sind im Graustufen-Farbraum definiert.