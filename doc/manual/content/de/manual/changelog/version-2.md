---
title: "Version 2"
weight: 40
type: docs
---

## 2.9

### 2.9.15 (12.7.2017)

- PageType erzwingen bei NewPage, entferne NL/Tab beim Anfang und Ende eines Absatzes.

### 2.9.14 (27.6.2017)

- CSS verarbeitet font-family für eigene Elemente.

### 2.9.13 (27.6.2017)

- Fehlerkorrektur: nummerischen Entitäten in Daten. Neu: base64 dekodieren, filecontents.

### 2.9.12 (16.6.2017)

- Fehlerkorrektur PlaceObject/hreference=right und absoluter Platzierung.

### 2.9.11 (18.5.2017)

- Späte Auswertung von defaultcolor bei Pagetype, kleinere Fehlerkorrekturen.

### 2.9.10 (10.5.2017)

- Neuer Befehl: Groupcontents. Damit wird eine Gruppe in eine Tabellenzelle eingefügt. Fehlerkorrektur beim XPath-Parser und bei sd:current-framenumber().

### 2.9.9 (8.5.2017)

- Lazy Evaluation des Rasters in Pagetype ([#130](https://github.com/speedata/publisher/issues/130)), Fehlerkorrektur geschachtelte Tabellen ([#129](https://github.com/speedata/publisher/issues/129)), verbesserte Initialen (Farbe), Fehlerkorrektur Cursor ([#128](https://github.com/speedata/publisher/issues/128))

### 2.9.8 (24.4.2017)

- Fehlerkorrektur XML Attribute mit Anführungszeichen

### 2.9.7 (16.4.2017)

- Neuer Befehl Initial.

### 2.9.6 (21.3.2017)

- Verbesserungen bei Image/bleed="auto", extra Belegungsrahmen bei PlaceObject

### 2.9.5 (9.3.2017)

- Absolute Positionierung erlaubt allocate="yes".
- Neue interne Variablen _bleed, _pagewidth und _pageheight.
- Neues Attribut bleed="..." bei Image.

### 2.9.4 (24.2.2017)

- Box mit backgroundcolor="-" belegt nur die Zellen.

### 2.9.3 (20.2.2017)

- Fehlerkorrektur resetmarks, neues Attribut defaultcolor bei Pagetype, ungenutzte Befehle gelöscht.

### 2.9.2 (10.2.2017)

- Fehlerkorrektur für processing instructions im XML (werden ignoriert)
- Neues Feature: &lt;span> und andere Elemente in den Daten können mit CSS angesprochen werden.

### 2.9.1 (8.2.2017)

- Fehlerkorrektur: top-distance in Tr

## 2.8

### 2.8.1 (6.2.2017)

- Korrigiere Hotfolder (variables Verzeichnis)

## 2.7

### 2.7.13 (3.2.2017)

- Benutze Einstellung tempdir um imagecache zu ermitteln.

### 2.7.12 (26.1.2017)

- Neuer Befehl: DefineFontalias
- Fehlerkorrekturen für mehrseitige Tabellen

### 2.7.11 (16.1.2017)

- Makeindex: Seitenzahl-Attribut variabel machen
- Fehlerkorrektur: Objekte mit Höhe > 0 und »springe zur nächsten Zeile«
- Lösche Bilder vom Cache wenn 404-Fehler kommt.

### 2.7.10 (6.1.2017)

- Möglichkeit, den Level der Fehlerkorrektur zu setzen für QR-Codes.

### 2.7.9 (28.11.2016)

- allowbreak=" " umbricht nicht mehr bei einem Trennstrich.
- NoBreak Voreinstellung ist nun 'keeptogether'. Dies verhindert einen Zeilenumbruch.

### 2.7.8 (25.11.2016)

- Wandle U+2011 (NON-BREAKING HYPHEN) in U+002D (HYPHEN-MINUS) um und füge keinen Umbruch ein.

### 2.7.7 (21.10.2016)

- Vor dem ersten Lauf den Cache nicht löschen.

### 2.7.6 (14.10.2016)

- Verbesseter Bild-Cache. Bilder in einem Lauf nicht erneut herunter laden.

### 2.7.5 (12.10.2016)

- Neue Methode für Bild-Caching. Umbenennung von Image/maxsize nach visiblebox.

### 2.7.4 (3.10.2016)

- Neuer Befehl Trace für verschiedene Debugging-Varianten, entferne show-* bei Optionen.
- Verhaltensänderung bei NextRow, EmptyLine wird nicht mehr unterstützt, Rückwärtskompatibilität mit dem Befehl Compatibility.
- Neue Option: defaultarea.

### 2.7.3 (14.9.2016)

- Neue API /v0/statusfile/&lt;id> um die Datei publisher.status zu erhalten.

### 2.7.2 (14.9.2016)

- Wenn PlaceObject über den rechten Rand hinaus geht (z.B. bei Text in voller Breite), gehe zur nächsten Zeile.

### 2.7.1 (8.9.2016)

- Fehlerkorrektur wenn fallback-Bild nicht gefunden wurde.
- Leere Attribute im Befehl Attribute erzeugen keine Tabelle

### 2.7.0 (18.8.2016)

- Schalte deutsche Layoutregeln ab, Fehlerkorrektur (104) Distribution ZIP-Datei

## 2.6

### 2.6.1 (18.8.2016)

- Fehlerkorrektur für Mac und Linux ZIP-Dateien

## 2.5

### 2.5.13 (10.8.2016)

- Fehlerkorrektur für lange Tabellen (> 200 Seiten?)

### 2.5.12 (8.8.2016)

- Fehlerkorrekturen für Absatzformen, verschiebe LuaTeX-Binary in ein anderes Verzeichnis

### 2.5.11 (2.8.2016)

- Füge padding-* zu Stylesheet hinzu, erlaube CSS für Image (derzeit nur padding), erlaube padding-* für Image

### 2.5.10 (2.8.2016)

- Viele Verbesserungen für Text/Output und allocate="yes"
- Ale Deutschen Befehle aus dem Handbuch gelöscht
- Neue Attribute für Text: fontface, color and textformat
- Verbesserungen in der Dokumentation (Tippfehler korrigiert), Sprachstring "English (Great Britan)" korrigiert

### 2.5.9 (6.7.2016)

- Fehlerkorrektur bzgl. langen Tabellen in Gruppen

### 2.5.8 (2.7.2016)

- Fehlerkorrektur beim Finden der nächsten freien Zeile

### 2.5.7 (25.6.2016)

- Fehlerkorrektur bei Belegung von nicht-Ganzzahl Spalten

### 2.5.6 (25.6.2016)

- Lösche alten Befehl ProcessRecord, neue Option bei BearbeiteDatensatz: umfang, Fehlerkorrektur bei Ausgabe/Text ([#89](https://github.com/speedata/publisher/issues/89))

### 2.5.5 (23.6.2016)

- Verschiedene Fehlerkorrekturen / Zukünftige Objekte und Tabellen

### 2.5.4 (20.6.2016)

- Kontrolle über die Größe des Hintergrundtexts in Td erlauben.

### 2.5.3 (18.6.2016)

- Fehlerkorrekturen von 2.4.4 eingefügt

### 2.5.2 (13.6.2016)

- (2.4.2) Einige Fehlerkorrekturen im Zusammenhang mit sd:aktuelle-rahmennummer(), minhöhe im Textblock und der Suche nach der nächsten freien Zeile.

### 2.5.1 (10.6.2016)

- Interpretiere &lt;sub> und &lt;sup> in den Daten.
- Fehlerkorrektur: Seitentyp und NeueSeite, Versionszusicherung im Layout-Tag

## 2.4

### 2.4.4 (18.6.2016)

- Verschiedene Fehlerkorrekturen: Führungspunkte verschwinden bei einem Zeilenwechsel, KeinUmbruch erlaubt die Angabe einer Schriftfamilie, Attribut-Werte werden nicht escaped, kaputte Bilder (ohne DPI-Angaben) werden besser behandelt.

### 2.4.3 (17.6.2016)

- Fehlerkorrektur zu einem fehlerhaften Fix in 2.4.2 bzgl. der Suche nach der nächsten freien Zeile für ein Objekt.

### 2.4.2 (13.6.2016)

- Einige Fehlerkorrekturen im Zusammenhang mit sd:aktuelle-rahmennummer(), minhöhe im Textblock und der Suche nach der nächsten freien Zeile.

### 2.4.1 (9.6.2016)

- Fehlerkorrektur: Seitentyp und NeueSeite, Versionszusicherung im Layout-Tag

### 2.4.0 (7.6.2016)

- Veröffentlichung von Version 2.4.0

## 2.3

### 2.3.77 (6.6.2016)

- Fallback für den Dateinamen bei Bild, im Falle dass die Bilddatei nicht gefunden wird.

### 2.3.76 (2.6.2016)

- Neue API /v0/layout/&lt;id> um die Layoutdatei zu bekommen

### 2.3.75 (31.5.2016)

- Neue API /v0/data/&lt;id> um die Datendatei zu bekommen
- Fehlerkorrektur: leere Wert-Angaben erzeugen einen Leerraum

### 2.3.74 (23.5.2016)

- Neue API /v0/status für alle Stati

### 2.3.73 (20.5.2016)

- Rahmennummer bei sd:belegt()

### 2.3.72 (28.4.2016)

- Fehlerkorrektur: Elementnamen mit - akzeptiert

### 2.3.71 (28.4.2016)

- Neue XPath-Funktion sd:belegt(x,y,name)

### 2.3.70 (26.4.2016)

- Nachrichten können einen Fehlercode setzen

### 2.3.69 (25.4.2016)

- Fehlerkorrektur: einrücken und Absatzform (belegen="auto")

### 2.3.68 (8.4.2016)

- Fehlerkorrektur: API /v0/pdf/&lt;id> muss auf die PDF-Datei warten. Fehler tritt bei mehreren Durchläufen auf

### 2.3.67 (7.4.2016)

- FürAlle hat ein neues Attribut: start um den Startpunkt festzulegen (Voreinstellung ist 1)

### 2.3.66 (5.4.2016)

- Verändere den Mechanismus, wie Text Bilder umfließt.

### 2.3.65 (29.3.2016)

- Verschiedene Fehlerkorrekturen zu HTML-Ausgabe und Ausgabe/Text

### 2.3.64 (21.3.2016)

- Unterstreichen in Daten beachtet CSS Styles

### 2.3.63 (18.3.2016)

- Fehlerkorektur Zeilenhöhe berechnen bei Ausgabe/Text und belegen=auto

### 2.3.62 (17.3.2016)

- Verschiedene Fehlerkorrenturen: Absatzform, Server wartet bis Durchlauf zuende

### 2.3.61 (14.3.2016)

- Neues Feature. U/gestrichelt="ja"

### 2.3.60 (14.3.2016)

- Fehlerkorrektur für HTML-Tabellen und sp --ignore-case / Schriftarten

### 2.3.59 (24.2.2016)

- Fehlerkorrektur HTML-Tabellen

### 2.3.58 (22.2.2016)

- Experimentelle HTML-Tabellen

### 2.3.57 (19.2.2016)

- Neue Option --ignore-case für den Klein- und Großbuchstabenunabhängigen Dateizugriff

### 2.3.56 (18.2.2016)

- Fehlerkorrektur in Ausgabe/belegen="auto"

### 2.3.55 (18.2.2016)

- halign bei ObjektAusgeben
- Verbessertes Umfließen von Objekten bei Ausgabe/belegen="auto".

### 2.3.54 (8.2.2016)

- Neue XPath-Funktion sd:zufallswert(Wert, Wert, Wert)

### 2.3.53 (6.2.2016)

- KeinUmbruch erlaubt das Abschneiden von Text mit ...
- PDF Producer wird auf LuaTeX gesetzt, Creator auf speedata Publisher - Versionsnummer
- Diverse Fehlerkorrekturen

### 2.3.52 (21.1.2016)

- Verschiedene Fehlerkorrekturen: mehrfache Absätze mit Absatzform, decode-html

### 2.3.51 (18.1.2016)

- Temporäres Verzeichnis konfigurierbar.

### 2.3.50 (18.1.2016)

- Gestrichelte Linien
- Führungslinien in HLeerraum

### 2.3.48 (12.1.2016)

- Server Modus: IDs starten immer mit einen nicht-Null Wert.

### 2.3.47 (11.1.2016)

- Neue PDFOption Duplex

### 2.3.46 (8.1.2016)

- Vertikaler Abstand zwischen Rasterzellen
- PDF Optionen Fachauswahl und Seitenskalierung

### 2.3.45 (18.12.2015)

- API Aufruf /v0/status gibt den Zeitstempel zurück.

### 2.3.44 (16.12.2015)

- Schreibe Warnungen in die status-Datei

### 2.3.43 (15.12.2015)

- Optionen / bildnichtgefunden: fehler oder warnung

### 2.3.42 (13.12.2015)

- Zugriff auf foo/@bar Attribute in Kindelementen
- Neue Form: Kreis

### 2.3.41 (10.12.2015)

- Neue XPath-Funktion substring()

### 2.3.40 (8.12.2015)

- Fehlerkorrektur beim Einlesen der Konfigurationsdatei

### 2.3.39 (7.12.2015)

- Server-Modus beachtet jobname aus der Datei publisher.cfg.

### 2.3.38 (30.11.2015)

- Neue XPath-Funktion 'string-length()', Fehlerkorrekturen, Vorbereitung auf LuaTeX 0.85

### 2.3.37 (19.11.2015)

- Fehlerkorrektur für kaputte Status-Datei / utf8

### 2.3.36 (19.11.2015)

- Provisorische Lösung für kaputte publisher.status-Datei
- Tabellen und vreferenz=unten funktionieren zusammen.

### 2.3.35 (6.11.2015)

- Schematron-Regeln im RelaxNG Schema
- Bild/href: man kann das file: Schema weglassen.

### 2.3.34 (4.11.2015)

- Fehlerkorrektur: Konfigurationsdatei benötigt Zeilenende in der letzten Zeile

### 2.3.33 (4.11.2015)

- Fehlerkorrektur bei LoadDataset und Windows

### 2.3.32 (18.9.2015)

- Fehlerkorrektur: Höhenberechnung in Tabellen mit Zeilen bei denen umbruch-unten=nein ist.
- Stark verbessertes Tabellen-Debugging mit --trace
- Dynamische Tabellenköpfe können gelöscht werden
- Aktion / Marke kann mehrere Einträge enthalten

### 2.3.31 (12.9.2015)

- Neue XPath-Funktion 'contains()'

### 2.3.30 (8.9.2015)

- Neuer API-Aufruf /v0/delete/id um den Publishing-Aufruf zu löschen
- Neue XPath-Funktion sd:alternierend-beibehalten() um den aktuellen Wert weiter zu benutzen.

### 2.3.29 (24.8.2015)

- Fehlerkorrektur im Server-Modus auf Windows

### 2.3.28 (11.8.2015)

- Textblock kann eine minimale Höhe haben.
- Option crop kann eine Längenangabe verarbeiten.

### 2.3.27 (7.8.2015)

- Fehlerkorrektur für Überlagern: Bild kann über eine anderes Element überlagert werden.

### 2.3.26 (7.8.2015)

- Neuer Befehl Überlagern um Objekte übereinanderzulegen.

### 2.3.25 (5.8.2015)

- Neue Kommandozeilenoption --extra-xml und neue Konfiguration extraxml um zusätzliche XML-Dateien den Layoutanweisungen hinzuzufügen (wie xinclude).
- Neue Option in der Konfigurationsdatei um zusätzliche Variablen zu definieren.
- Neuer Parameter vars im Server-Modus, um zusätzliche Variablen für den Publishing-Prozess anzugeben.
- Neue Kommandozeilenoption --varsfile um weitere Variablen zu definieren.

### 2.3.24 (26.6.2015)

- Neue Option »beschnittzugabemarken«, Darstellung der Trim-Box wenn show-grid angeschaltet ist.

### 2.3.23 (25.6.2015)

- Fehlerbehebung in der Breitenberechnung im Raster

### 2.3.22 (19.6.2015)

- Fehlerkorrektur bei dx und nx in SetzeRaster

### 2.3.21 (30.5.2015)

- Neue Option »beschnitt« für Seiten mit einer CropBox, die den Objekten auf der Seite entspricht.

### 2.3.20 (21.4.2015)

- Fehlerkorrektur: Breite bei Tabelle und Linie in Kombination mit Rasterzellenabstand

### 2.3.19 (20.4.2015)

- Platzierungsrahmen dürfen nun auf Daten zugreifen ({@attrib} zum Beispiel)
- Fehlerkorrektur/Workaround für einen Fehler in zentrierten Td-Zellen mit mehreren Zeilen.

### 2.3.18 (8.4.2015)

- Fehlerkorrekturen: replace() und $1, $2, ... / &lt;Td align="center">...&lt;/Td> Inhalte mit mehrern Zeilen.

### 2.3.17 (25.3.2015)

- Experimentelle Garbage-Collection bei Zuweisung.

### 2.3.16 (11.3.2015)

- Befehl KeinUmbruch um einen Zeilenumbruch innerhalb des Elements zu verhindern.

### 2.3.15 (9.3.2015)

- API Änderungen: jobname ist per URL-Parameter konfigurierbar, bessere Fehlermeldungen

### 2.3.14 (4.3.2015)

- Server-Modus: /v0/pdf/&lt;id&gt; gibt das PDF zurück
- Server-Modus: Zeitstempel für /v0/publish/&lt;id&gt;

### 2.3.12 (27.2.2015)

- Neuer API Aufruf /available -> 200 OK, /v0/publish gibt 201 zurück

### 2.3.11 (26.2.2015)

- Rasterabstand horizontal kann eingestellt werden.

### 2.3.10 (25.2.2015)

- Fehlerkorrektur: Indexeintrag ohne Inhalt lässt den Publisher abstürzen.

### 2.3.9 (24.2.2015)

- Fehlerkorrekturen (sp server-Modus .protocol Datei, Endlosschleife bei fehlerhaften UTF8-Daten)
- Leere Attribute (attr="") werden als nil behandelt. empty(@attr) gibt jetzt true() zurück.

### 2.3.8 (21.2.2015)

- Drehung in 90°-Schritten bei Bildern
- Neue XPath-Funktion sd:seitenverhältnis('bildname.png')
- Einfache if/then/else Ausdrücke in XPath

### 2.3.7 (19.2.2015)

- Hintergrundtext für Tabellenzellen (td)

### 2.3.6 (12.2.2015)

- Die Datei publisher.status enthält die Nachrichten und Fehlermeldungen.

### 2.3.4 (27.1.2015)

- Fehlerkorrektur: Sonderfarben gelten nun für Striche und Flächen

### 2.3.3 (26.1.2015)

- Ein paar CSS-Regeln für Linie, direkte Farbdefinition.

### 2.3.2 (22.1.2015)

- Neuer Server-Modus für entferntes Publishing.

## 2.2

### 2.1.36 (15.1.2015)

- Alle CSS Level 3 Farben hinzugefügt (siehe https://www.w3.org/TR/css-color-3/ für eine Liste)

### 2.1.35 (19.12.2014)

- Lesezeichen auf allen Ebenen erlauben (experimentell)

### 2.1.34 (18.12.2014)

- Neue Funktion sd:attr(), um auf Attribute mit dynamischen Namen zuzugreifen.

### 2.1.32 (1.12.2014)

- Der XML-Parser beachtet --extra-dir bei XInclude

### 2.1.28 (11.11.2014)

- Trennzeichen kann in Textformat festgelegt werden.

### 2.1.27 (6.11.2014)

- Neues Beispiel "Serienbriefe"

### 2.1.26 (29.10.2014)

- Neuer Befehl: Rahmen. Kann als Beschneidungspfad für innenliegende Ojbekte genommen werden.

### 2.1.23 (13.10.2014)

- Abgerundete Ecken bei ObjektAusgeben / Rahmen

### 2.1.22 (9.10.2014)

- Transformationen können in ObjektAusgeben geschachltelt werden.

### 2.1.21 (8.10.2014)

- Benutzerdefinierte Sonderfarben
- Transformations-Ursprung bei drehen und matrix (ObjektAusgeben)

### 2.1.20 (16.9.2014)

- Kopie-von zerstört nicht den Inhalt.

### 2.1.18 (9.9.2014)

- Eine Transformationsmatrix kann bei ObjektAusgeben angegeben werden.

### 2.1.16 (22.8.2014)

- Zeilen dürfen bei / nicht mehr umbrochen werden, außer in erlaubeumbruch enthält den Schrägstrich.

### 2.1.15 (18.8.2014)

- Experimenteller Servermodus (/v0/format)

### 2.1.14 (15.8.2014)

- Silbentrennung bei DefiniereTextformat an- und ausschaltbar

### 2.1.13 (12.8.2014)

- Grundlegende Unterstützung von tokenize() und replace(), erste Funktionalität des Server-Modus.
- Farben können die Eigenschaft »überdrucken« haben.
- Sonderfarben (PANTONE und HKS)

### 2.1.12 (25.7.2014)

- Neuer Befehl »Farbe« um vorübergehend die Textfarbe zu ändern.

### 2.1.10 (3.7.2014)

- Das Verhalten von erlaubeumbruch bei Absatz wurde geändert. Das Leerzeichen muss explizit angegeben werden.
- Neue XPath-Funktion sd:blindtext() und sd:loremipsum() für Beispieltext (lorem ipsum)

### 2.1.9 (27.6.2014)

- XInclude wieder aktiviert.

### 2.1.8 (24.6.2014)

- Tabellenzeilen (Tr) können als Tabellenkopf wiederbenutzt werden.
- Seitenzahlen zusammenfassen verarbeitet Seitenbereiche.

### 2.1.7 (6.6.2014)

- Fehlerkorrektur für Tabellen in Tabellen, die rechtsbündig gesetzt werden sollen.

### 2.1.6 (5.6.2014)

- Experimentelle Option 'erlaubeumbruch' bei Absatz um eine Liste der möglichen Trennpunkte anzugeben.
- sp --quiet unterdrückt die Ausgabe
- sp compare parallelisiert für höhrere Geschwindigkeit.

### 2.1.5 (28.5.2014)

- Fehlerbehebung bei Tabellenzellen mit align="center" und fixer Breite.

### 2.1.3 (20.5.2014)

- Trennung im zweiten Wort in zusammengesetzten Wörtern erlauben, Umbruch möglich nach "/"

### 2.1.1 (19.5.2014)

- Neue Implementierung des Textumbruchs in Spalten. Vollständig abwärtskompatibel.

### 2.1.0 (15.5.2014)

- Neues Verhalten von Elementen in Tabellenzellen (Td). Nun wird, soweit sinnvoll, die Logik von HTML angewandt (siehe https://developer.mozilla.org/en-US/docs/Web/HTML/Block-level_elements -HTML Blockelemente).

