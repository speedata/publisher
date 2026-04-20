---
title: "Version 3"
weight: 30
type: docs
---

## 3.9

### 3.9.36 (7.9.2020)

- Neue Option reportmissingglyphs="warning".

### 3.9.35 (26.8.2020)

- Fehlerkorrektur bei leerem Value-Element.

### 3.9.34 (24.8.2020)

- Sicheres Laden von harfbuzz, neue Binaries für Windows/Mac/Linux.

### 3.9.33 (23.8.2020)

- harfbuzz auf Windows deaktivieren.

### 3.9.32 (21.8.2020)

- Experimenteller (nicht unterstützter) harfbuzz shaper.

### 3.9.31 (16.8.2020)

- Interaktionen (Hyperlinks) als Voreinstellung.

### 3.9.30 (14.8.2020)

- Korrigiere Hyperlinks (kein Rahmen im Acrobat, Interaktion ist Voreinstellung).

### 3.9.29 (14.8.2020)

- Fehlerkorrektur für ForAll und gefilterten Werten ([#261](https://github.com/speedata/publisher/issues/261)).

### 3.9.28 (3.8.2020)

- Fehlerkorrektur für rowspan/colspan-Berechnung. ([#259](https://github.com/speedata/publisher/issues/259))

### 3.9.27 (31.7.2020)

- padding-left und padding-right bei Paragraph. ([#258](https://github.com/speedata/publisher/issues/258))

### 3.9.26 (29.7.2020)

- Neue XPath-Funktionen firstmark und lastmark um die ersten und letzten Marker einer Seite zu bekommen.
- Neue interne Variable `$_lastpage`, die die letzte Seitenzahl des vorherigen Laufs enthält.

### 3.9.25 (26.7.2020)

- Fehlerkorrektur für Farbe bei Unterstreichen ([#256](https://github.com/speedata/publisher/issues/256)).
- Schemaverbesserungen ([#257](https://github.com/speedata/publisher/issues/257)).

### 3.9.24 (10.7.2020)

- Neue Option randomseed.
- Fehlerkorrektur für Hyperlinks am Ende der Zeile ([#255](https://github.com/speedata/publisher/issues/255)).

### 3.9.23 (5.7.2020)

- Servermodus: `/v0/pdf/‹id›` löscht die PDF-Datei auf dem server nach dem Request.

### 3.9.22 (5.7.2020)

- Servermodus: konfigurierbarer Filter und extra Verzeichnisse, neuer Konfigurationsabschnitt `server`.

### 3.9.21 (3.7.2020)

- Lua Filter: `runtime.find_file` gibt den absoluten Pfad einer Ressource zurück (Datei oder URL).

### 3.9.20 (2.7.2020)

- Servermodus: Modi in der URL angeben.

### 3.9.19 (1.7.2020)

- HTML Support verbessert (margin-top, margin-bottom und andere).

### 3.9.18 (25.6.2020)

- HTML Support verbessert.

### 3.9.17 (22.6.2020)

- Fehlerkorrektur QR-Code (aus dem master-Repository).
- CSS border-radius.

### 3.9.16 (12.6.2020)

- Fehlerkorrektur HTML, Handbuch aktualisiert.

### 3.9.15 (10.6.2020)

- Update auf LuaTeX 1.12 (ohne sichtbare Änderungen).
- Neues Handbuch Englisch.

### 3.9.14 (19.5.2020)

- Verschiedene Korrekturen, die in den letzten Entwicklungsversionen eingebaut wurden.

### 3.9.13 (15.5.2020)

- Fehlerkorrektur zum Finden der ausführbaren Datei ([#254](https://github.com/speedata/publisher/issues/254)).

### 3.9.12 (12.5.2020)

- Zwei Fehlerkorrekturen im HTML-Modus ([#252](https://github.com/speedata/publisher/issues/252) und [#253](https://github.com/speedata/publisher/issues/253)).

### 3.9.11 (12.5.2020)

- Neuer HTML Modus: bessere Tabellendarstellung.

### 3.9.10 (10.5.2020)

- Neuer HTML Modus: `sp html meinedatei.html`.
- Zweites Argument für sd:imageheight, sd:imagewidth für genaue Größe.
- `Image` als Kind von `Output` möglich.

### 3.9.9 (21.4.2020)

- Verbesserte HTML Unterstützung.

### 3.9.8 (3.4.2020)

- Neue Option PDFOptions/showbookmarks für Adobe Acrobat.

### 3.9.7 (31.3.2020)

- Fehlerkorrektur: doppelter hyperlink in einer Zeile ([#251](https://github.com/speedata/publisher/issues/251))
- CSS: Tabelle mit 100% breite, td: Ausrichtung
- Textformat: setze margin am oberen Ende der umgebenden Box.
- Erste (Vorab-) Version des neuen HTML-Parsers.

### 3.9.6 (12.3.2020)

- Tabellenausgleich: einzelne Tabellenlinie in der letzten Spalte geht in die vorherige Spalte. ([#250](https://github.com/speedata/publisher/issues/250))
- Korrektur: Einfache HTML-Tabelle ([#249](https://github.com/speedata/publisher/issues/249)).
- Korrektur: html Hyperlinks mit widow/orphan Kontrolle ([#248](https://github.com/speedata/publisher/issues/248)).
- Korrektur: run_saxon() schlägt fehl.
- Korrektur: backgroundcolor in Tabellenzellen, wenn es Voreinstellungen in `Column` gibt ([#247](https://github.com/speedata/publisher/issues/247)).

### 3.9.5 (25.2.2020)

- Korrigiere Höhenberechnung für Zellbelegung.

### 3.9.4 (14.2.2020)

- Neuer Weg, um run_saxon in der Vorverarbeitung zu starten.

### 3.9.3 (10.2.2020)

- Setze Logdatei für Servermodus.

### 3.9.2 (27.1.2020)

- Neue Option interaction, um hyperlinks im Dokument zu deaktivieren, U+2011 wird nun beachtet.

### 3.9.1 (16.1.2020)

- Externe Bild-Konvertierungstools.

## 3.8

### 3.8.0 (14.1.2020)

- Veröffentliche stabile Version 3.8.0.

## 3.7

### 3.7.24 (6.1.2020)

- Fehlerkorrekturen ([#242](https://github.com/speedata/publisher/issues/242), [#174](https://github.com/speedata/publisher/issues/174), [#239](https://github.com/speedata/publisher/issues/239)). Vorbereitung für 3.8.

### 3.7.23 (19.12.2019)

- Neue cache-Option "none".

### 3.7.22 (11.12.2019)

- Verbesserung beim caching von externen Medien.

### 3.7.21 (11.12.2019)

- Verbesserung beim Download von Medien.

### 3.7.20 (27.11.2019)

- Neuer Kommandozeilenparameter: setze Image cache.

### 3.7.19 (25.11.2019)

- Bugfix für Tabellenausgleich ([#243](https://github.com/speedata/publisher/issues/243)).

### 3.7.18 (22.11.2019)

- Neuer Finalizer-callback und HTTP-Modul im Lua-Filter.

### 3.7.17 (19.11.2019)

- Bessere Fehlermeldungen beim Laden externer Dateien ([#241](https://github.com/speedata/publisher/issues/241)).

### 3.7.16 (18.11.2019)

- Fehlerkorrektur 2 für Tabellenausgleich ([#240](https://github.com/speedata/publisher/issues/240)).

### 3.7.15 (5.11.2019)

- Fehlerkorrektur für Tabellenausgleich ([#240](https://github.com/speedata/publisher/issues/240)).

### 3.7.14 (31.10.2019)

- Halloween release. (Fehlerkorrektur für SavePages in Rückwärts-Modus).

### 3.7.13 (28.10.2019)

- Update auf LuaTeX version 1.11.1 für den neuen `page_order_index` callback.
- Zugriff auf Modi via `$_mode` Variable.
- Entferne feature »insert after« bei NewPage.

### 3.7.12 (22.10.2019)

- Neuer Kommandozeilenbefehl `mode` für alternative Code-Ausführung.
- Seiten umordnen mit `SavePages` und `InsertPages`.

### 3.7.11 (9.10.2019)

- Seitenzahl bei Fehlern und Warnungen

### 3.7.10 (11.9.2019)

- Neuer Befehl 'sp new' für Beispieldateien.
- XML Schema (XSD) hinzufügen.

### 3.7.9 (3.9.2019)

- Options kann mehrfach in der Layoutdatei vorkommen.

### 3.7.8 (15.8.2019)

- sd:group-width() hat einen zweiten Parameter um die exakte Breite zu erhalten, genau wie sd:group-height().
- Papierformat kann erneut gesetzt werden.
- Drehung in Tabellenzellen verbessert.

### 3.7.7 (18.7.2019)

- Ersatzfonts für LoadFontfile.

### 3.7.6 (1.7.2019)

- Elemente in Message erlauben.
- Neue XPath Funktion number().
- Fehlerkorrektur Initialen und Zeilenhöhe.

### 3.7.5 (12.6.2019)

- Fehlerkorrektur textformat/fill-last-line ([#234](https://github.com/speedata/publisher/issues/234)).
- Fehlerkorrektur valign=bottom ([#233](https://github.com/speedata/publisher/issues/233)).

### 3.7.4 (21.5.2019)

- Fehlerkorrektur Tabellenausgleich ([#232](https://github.com/speedata/publisher/issues/232)).

### 3.7.3 (2.5.2019)

- AttachFile: setze den PDF-Namen der eingebundenen Datei.

### 3.7.2 (28.4.2019)

- Fehlerkorrektur: TD mit align=right und nur Leerzeichen im Inhalt ([#230](https://github.com/speedata/publisher/issues/230)).
- AttachFile kann die Daten von einem XML-Knoten lesen (anstelle einer externen Ressource).

### 3.7.1 (2.4.2019)

- Fehlerkorrekturen ([#221](https://github.com/speedata/publisher/issues/221), [#225](https://github.com/speedata/publisher/issues/225), [#226](https://github.com/speedata/publisher/issues/226), [#228](https://github.com/speedata/publisher/issues/228), [#229](https://github.com/speedata/publisher/issues/229)).

## 3.6

### 3.6.0 (13.2.2019)

- Veröffentliche Version 3.6.0

## 3.5

### 3.5.13 (13.2.2019)

- Fehlerkorrektur für valign="botton" in PlaceObject ([#222](https://github.com/speedata/publisher/issues/222))
- Fehlerkorrektur Zeilenabstand in Absätzen für kleine Schriftgrade ([#221](https://github.com/speedata/publisher/issues/221))
- Fehlerkorrektur URL Umbruch ([#173](https://github.com/speedata/publisher/issues/173))
- Fehlerkorrektur Textformat tracing ([#172](https://github.com/speedata/publisher/issues/172))

### 3.5.12 (31.1.2019)

- Fehlerkorrektur für Tabellenausgleich und break-below=no

### 3.5.11 (27.1.2019)

- Tabellen-Ausgleich: setze aktuelle Ausgabezeile.
- Tabellen-Ausgleich beachtet die Zeilenhöhe.

### 3.5.10 (21.12.2018)

- Verschiedene Fehlerkorrekturen. XProc wird nicht mehr unterstützt. Neues Attribut clip bei Frame. Trennmuster aktualisiert. XInclude für Datendateien. Benutze Go 1.11 Module.

### 3.5.9 (29.11.2018)

- Seitenrand 1cm als Voreinstellung. Fehlerkorrektur bei dynamischen Tabellenkopf und balance="yes".

### 3.5.8 (28.11.2018)

- Kleine Fehlerkorrekturen.

### 3.5.7 (21.11.2018)

- Fehlerkorrektur bei Tabellenausgleich und Cursorpositionierung ([#202](https://github.com/speedata/publisher/issues/202)).
- Unterstützung für PDF/X-3 und PDF/X-4.
- Grundlegende Unterstützung für PDF/UA (Barrierefreiheit).

### 3.5.6 (9.11.2018)

- Rotation in Tabellenzellen verbessert.

### 3.5.5 (30.10.2018)

- Konvertiere SVG automatisch mit Inkscape.
- Optionaler Dateiname im XML-Writer des Luafilters.

### 3.5.4 (4.10.2108)

- Neuer Dateiloader erlaubt vielfältige Arten der Dateieinbindung.
- Erlaube das Einbinden von Dateien mit nicht-Ascii-Dateinamen unter Windows.

### 3.5.3 (25.9.2018)

- Verschiedene Fehlerkorrekturen (HTML-Links in Daten, PDF-dest zu tief [#198](https://github.com/speedata/publisher/issues/198)).

### 3.5.2 (18.9.2018)

- Sperrung in Span.
- Break-below funktioniert mit Tabellenlinien.
- CID Schriftarten können benutzt werden.
- Fehlerkorrektur für `upper-case()`, `lower-case()` und `replace()`.
- Verschiedene Fehlerkorrekturen für LuaTeX 1.0.7.

### 3.5.1 (5.9.2018)

- Erstes Release mit dynamischer Bibliothek, hauptsächlich für Tests.

## 3.4

### 3.4.0 (3.9.2018)

- Veröffentliche Version 3.4.0

## 3.3

### 3.3.14 (30.8.2018)

- Update auf LuaTeX Version 1.0.7
- sp compare HTML Statusreport
- TCP Verbindung auf localhost beschränken

### 3.3.13 (22.8.2018)

- Neuer Befehl TableNewPage um in einer Table eine neue Seite zu beginnen.
- Zugriff auf Benutzer-Variablen im Lua-Filter
- Neue XPath-Funktion lower-case()

### 3.3.12 (13.8.2018)

- Fehlerkorrektur bei der Berechnung der Breite von Tabellenzellen
- Ellipsen können mit dem Befehl circle erzeugt werden.

### 3.3.11 (8.8.2018)

- Fehlerkorrektur für Tabellen, die sich über mehrere Bereiche erstrecken ([#191](https://github.com/speedata/publisher/issues/191))
- Sicherstellen, dass die letzte Zeile eines Absatzes eine minimale Länge hat ([#188](https://github.com/speedata/publisher/issues/188))

### 3.3.10 (31.7.2018)

- sd:group-height() mit einem zweiten Argument (Einheit), die Ausgabe ist das Vielfache der Einheit.
- Bookmarks ändern nicht den Zoom-Faktor des PDFs
- Fehlerkorrektur für NoBreak
- Neue Lua-Implementierung für den Filter (yuin/gopher-lua anstelle von Shopify/go-lua)

### 3.3.9 (18.6.2018)

- Verschiedene Fehlerkorrekturen, Zugriff auf `$_jobname`

### 3.3.8 (18.6.2018)

- SaveDataset: Attribut `filename` umbenannt nach `name`.
- Hyperlinks innerhalb von Dokumenten
- Bookmarks in dynamischen Tabellenköpfen erlabut (Tr/sethead='yes')
- XPath: korrigiere Vergleich von Elementen und einzelnen Werten.

### 3.3.7 (13.6.2018)

- Textdrehungen in Tabellenzellen (Td)

### 3.3.6 (1.6.2018)

- Fehlerkorrektur in Textformat/spacebelow ([#171](https://github.com/speedata/publisher/issues/171))

### 3.3.5 (30.5.2018)

- Neues Attribut `minwidth` um die minimale Breite des Leerraums bei `HSpace` einzustellen.
- Verschiedene Fehlerkorrekturen: leaders in Tabellen, Dokumentationslinks, `space="..."` bei `LoadFontfile`
- Neue XPath-Funktion `local-name()`
- HTML erlaubt nun auch em
- »Neues« Farbschema RGB für Werte zwischen 0 und 255
- Sprache »French« zum Schema hinzufügen

### 3.3.4 (16.5.2018)

- Fehlerkorrektur für Strg-c, um den Publisher-Durchlauf zu beenden und Output/balance="yes"

### 3.3.3 (15.5.2018)

- Fehlerkorrektur: Seitenformat kann von der Datenquellen genommen werden.
- Korrigiere QR-Code Erzeugung.

### 3.3.2 (20.4.2018)

- Bugfix Höhenberechnung Output/Text und balance="yes"

### 3.3.1 (16.4.2018)

- Balance: padding-bottom und valign auf der letzten Seite
- Output/Text balance="yes" und textformat/column-padding-top

## 3.2

### 3.2.0 (27.3.2018)

- Veröffentliche Version 3.2.0

## 3.1

### 3.1.28 (27.3.2018)

- Verbesserungen im Handbuch

### 3.1.27 (23.3.2018)

- Weitere Fehlerkorrektur bei Tabellen

### 3.1.26 (23.3.2018)

- Fehlerkorrektur bei Tabellen ([#166](https://github.com/speedata/publisher/issues/166))
- Fehlerkorrektur bei Ul/Li

### 3.1.25 (20.3.2018)

- Fehlerkorrektur bei XPath ([#165](https://github.com/speedata/publisher/issues/165))
- Das neue deutsche Handbuch einbegunden

### 3.1.24 (16.3.2018)

- Neues Feature: Table/balance="yes" für Spaltenausgleich.

### 3.1.23 (14.3.2018)

- Tr/minheight erlaubt Längenangaben

### 3.1.22 (9.3.2018)

- PlaceObject: Absolute Positionierung verbessern
- SortSequence: umgekehrte Reihenfolge erlauben
- Detaillierte Optionen für Schusterjungen und Hurenkinder

### 3.1.21 (16.2.2018)

- Fehlerkorrektur für mehrseitige Tabellen
- Neue Default-Fonts

### 3.1.20 (1.2.2018)

- Viele Verbesserungen im Font-Bereich, erste Versuche, Chinesisch korrekt zu setzen

### 3.1.19 (30.1.2018)

- PDF Titel und Autor setzen ist nun möglich

### 3.1.18 (29.1.2018)

- Löse Problem mit Zeichenzuordnung

### 3.1.17 (28.1.2018)

- Fehlende Zeichen werden angemerkt
- exit="yes" bei Message um den Publishing-Durchlauf zu beenden

### 3.1.16 (19.12.2017)

- Andere Namensräume in der Layoutdatei erlauben
- Fehlerkorrektur für FontFix

### 3.1.15 (7.12.2017)

- Neuer Befehl Span für farbige Hintergründe

### 3.1.14 (1.12.2017)

- Geschwindigkeit erhöht

### 3.1.13 (30.11.2017)

- Benutze exeSufix für sp compare auf Windows
- Fehlerkorektur für Output/allocate="auto"

### 3.1.12 (28.11.2017)

- Fehlerkorrektur für »zukünftige Seiten«

### 3.1.11 (23.11.2017)

- Lese Excel-Dateien und validiere RelaxNG
- Füge grundlegende Unterstützung für LuaTeX 1.0.4 hinzu

### 3.1.10 (3.11.2017)

- Verbessere den Lua-CSV-Reader

### 3.1.9 (31.10.2017)

- Neues Lua-basiertes Pre-processing

### 3.1.8 (24.10.2017)

- Neue XPath-Funktion round(), padding-* in Column

### 3.1.7 (22.10.2017)

- Verschiedene Fehlerkorrekturen (Raster, Fontface)

### 3.1.6 (27.9.2017)

- Verschiedene Fehlerkorrekturen

### 3.1.5 (8.9.2017)

- Neues Feature: DefineTextformat/tab=hspace ändert den Tabulator in einen dehnbaren Leerraum.

### 3.1.4 (6.9.2017)

- Fehlerkorrektur: Image/page geht nicht mit href zusammen

### 3.1.3 (22.8.2017)

- Neue XPath-Funktion `sd:dimexpr()` für Berechnungen mit Längenangaben

### 3.1.2 (31.7.2017)

- Fehlerkorrektur für Unterstreichen.

### 3.1.1 (28.7.2017)

- ZUGFeRD Integration, neue Befehle AttachFile und AddSearchpath

## 3.0

### 3.0.0 (25.7.2017)

- Veröffentliche Version 3.0

