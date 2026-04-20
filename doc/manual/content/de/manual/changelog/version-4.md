---
title: "Version 4"
weight: 20
type: docs
---

## 4.21

### 4.21.20 (11.3.2025)

- Entferne direction-Attribut bei Span.

### 4.21.19 (10.3.2025)

- Bessere Fehlermeldungen für interne Lua-Fehler.

### 4.21.18 (4.3.2025)

- Korrigiere Klammern im bidi-Modus ([#650](https://github.com/speedata/publisher/issues/650)).

### 4.21.17 (26.2.2025)

- Fehlerkorrektur im HTML-Modus.

### 4.21.16 (25.2.2025)

- Fehlerkorrektur: break-before="page" und break-below="no" in DefineTextformat ohne Effekt.

### 4.21.15 (25.2.2025)

- Textformat: erzwinge Seitenumbruch vor Element.

### 4.21.14 (19.2.2025)

- Korrigiere fehlerhafte Orientierung in bidi ([#649](https://github.com/speedata/publisher/issues/649)).

### 4.21.13 (18.2.2025)

- Verschiedene Fehlerkorrekturen (EAN13 Strichcodes, MetaPost Farben und neuer XPath Parser).
- Value/Function kann benutzt werden, um eine Tabellenzelle zu erzeugen ([#647](https://github.com/speedata/publisher/issues/647)).

### 4.21.12 (17.2.2025)

- Spaltenbreiten in Tabellen können dynamisch und fest sein ([#648](https://github.com/speedata/publisher/issues/648)).

### 4.21.11 (10.2.2025)

- Fehlerkorrektur NoBreak und unvollständige Fontfamilie ([#646](https://github.com/speedata/publisher/issues/646)).

### 4.21.10 (5.2.2025)

- Objekte können am Seitenrand abgeschnitten werde ([#640](https://github.com/speedata/publisher/issues/640)).

### 4.21.8 (3.2.2025)

- Diverse Fehlerkorrekturen und Dokumentationskorrekturen ([#582](https://github.com/speedata/publisher/issues/582), [#594](https://github.com/speedata/publisher/issues/594), [#611](https://github.com/speedata/publisher/issues/611), [#629](https://github.com/speedata/publisher/issues/629), [#630](https://github.com/speedata/publisher/issues/630)).
- Erlaube Debugausgabe des Rasters ([#569](https://github.com/speedata/publisher/issues/569)).

### 4.21.7 (31.1.2025)

- Fehlerkorrektur für Fallback im HarfBuzz-Modus.

### 4.21.6 (30.1.2025)

- Beginne Fallback für Schriftarten im HarfBuzz-Modus ([#603](https://github.com/speedata/publisher/issues/603)).

### 4.21.5 (23.1.2025)

- Erlaube Variablen in Pagetype und neuem XPath-Modus.

### 4.21.4 (22.1.2025)

- Fehlerkorrektur: font fallbacks und alter XPath-Modus.

### 4.21.3 (22.1.2025)

- Behebe Darstellungsfehler bei Tabellenlinien im Adobe Acrobat ([#644](https://github.com/speedata/publisher/issues/644)).

### 4.21.2 (20.1.2025)

- Bordercollapse neu schreiben ([#645](https://github.com/speedata/publisher/issues/645)).
- Entferne den weißen Hintergrund auf jeder Seite.

### 4.21.1 (17.1.2025)

- Fehlerkorrektur: Hyperlinks auf URLs nicht funktionsfähig.

### 4.21.0 (16.1.2025)

- bleed="auto" neu bei Box.
- Neue Dateiendung für temporäre Dateien (nun .xml anstelle von .dataxml).

## 4.20

### 4.20.0 (15.1.2025)

- Veröffentliche Version 4.20.

## 4.19

### 4.19.40 (15.1.2025)

- Sättigung für Sonderfarben.

### 4.19.39 (13.1.2025)

- Fehlerkorrektur Harfbuzz: mache Old-Style Ziffern und andere nicht-Standard Zeichen kopierbar im PDF.

### 4.19.38 (9.1.2025)

- Korrigiere Dateinamen bei ZUGFeRD-Anhängen.
- PDF/A-3 als Ausgabeformat erlauben.

### 4.19.37 (7.1.2025)

- Bessere ZUGFeRD Versionserkennung.
- Neue Möglichkeit um Objekte zu spiegeln ([#642](https://github.com/speedata/publisher/issues/642)).
- Schreibe OutputIntent bei ZUGFeRD PDF/A-Dateien. Damit wird ein Validierungsfehler behoben..
- Fehlerkorrektur: fallback für Schriftdateien im fontforge-Modus ([#605](https://github.com/speedata/publisher/issues/605)).
- Laxe und strenge Handhabung von XML-Namensräumen ([#641](https://github.com/speedata/publisher/issues/641)).
- Harfbuzz: mache Old-Style Ziffern und andere nicht-Standard Zeichen kopierbar im PDF.

### 4.19.36 (17.12.2024)

- Neue XPath-Funktion namespace-uri().
- Ändere ZUGFeRD Dateiname nach 'factur-x.xml'.
- Bessere Erkennung des ZUGFeRD Profils.

### 4.19.35 (2.12.2024)

- Fehlerkorrektur Border collapse und Colspan ([#636](https://github.com/speedata/publisher/issues/636)).

### 4.19.34 (26.11.2024)

- Korrigiere den Wert von last() im neuen XPath-Parser bei ProcessNode.

### 4.19.33 (24.11.2024)

- Option um Farbprofile bei Sonderfarben abzuschalten.

### 4.19.32 (22.11.2024)

- Fehlerkorrektur Bildgrößen in HTML und neuem XPath-Modus.
- Funktionen: gemischte Anweisungen und Werte sind erlaubt ([#627](https://github.com/speedata/publisher/issues/627)).

### 4.19.31 (4.11.2024)

- Option um Abstände und Größe der hoch/tiefgestellten Zeichen einzustellen ([#625](https://github.com/speedata/publisher/issues/625)).

### 4.19.30 (29.10.2024)

- Fehlerkorrektur sd:variable() und neuer XPath Parser ([#623](https://github.com/speedata/publisher/issues/623)).

### 4.19.29 (29.10.2024)

- Neue Margin Parameter inner und outer anstelle von links und rechts.

### 4.19.28 (28.10.2024)

- Neue Strategie `&lt;NoBreak reduce="fontfit" />` ([#622](https://github.com/speedata/publisher/issues/622)).

### 4.19.27 (23.10.2024)

- Daten XML nun im Wurzelelement des Layouts verfügbar ([#621](https://github.com/speedata/publisher/issues/621)).
- Fehlerkorrektur: SetGrid mit width/height nach nx/ny ([#619](https://github.com/speedata/publisher/issues/619)).

### 4.19.26 (5.10.2024)

- Fehlerkorrektur ClearPage in SavePages ([#617](https://github.com/speedata/publisher/issues/617)).

### 4.19.25 (2.10.2024)

- Korrigiere mehrfache InsertPages im »zukünftigen Modus«.

### 4.19.24 (30.9.2024)

- Fehlerkorrektur sd:count-saved-pages und neuer XPath-Modus.

### 4.19.23 (16.9.2024)

- PDF/UA Verbesserungen.

### 4.19.22 (6.9.2024)

- PDF/UA Verbesserungen.
- Verarbeite UTF-16 Dateien.

### 4.19.21 (4.9.2024)

- Rückwärts inkompatible Änderung: Ändere XPath Variablen Semantik ([#612](https://github.com/speedata/publisher/issues/612)).
- Korrigiere tab="hspace" in harfbuzz Modus.
- Reduziere unnötige Logging-Informationen.

### 4.19.20 (14.8.2024)

- SVG-Konvertierung nun Inkscape 1.0 voreingestellt.
- Entferne überflüssige ET/BT/EMC Befehle im Pagestream ([#602](https://github.com/speedata/publisher/issues/602)).

### 4.19.19 (24.7.2024)

- Fehlerkorrektur Image und width="100%" und lxpath Modus ([#600](https://github.com/speedata/publisher/issues/600)).
- Fehlerkorrektur NoBreak/fontsize und leere Eingabe ([#598](https://github.com/speedata/publisher/issues/598)).

### 4.19.18 (17.7.2024)

- Korrigiere NoBreak/fontsize und dynamische Daten ([#598](https://github.com/speedata/publisher/issues/598)).
- Fehlermeldung und Dokumentation bei `--prepend-xml` oder `--extra-xml` im lxpath-Modus ([#597](https://github.com/speedata/publisher/issues/597)).
- Optischer Randausgleich auch im Harfbuzz Modus ([#595](https://github.com/speedata/publisher/issues/595)).

### 4.19.17 (12.7.2024)

- Schriftbreiten-Parameter konfigurierbar machen.
- sp list-fonts funktioniert wieder.

### 4.19.16 (7.7.2024)

- Erweitere Möglichkeiten für Barrierefreiheit.

### 4.19.15 (4.7.2024)

- Neue Plattform: Linux ARM 64 Bit (experimentell).

### 4.19.14 (1.7.2024)

- Fehlerkorrektur Listen und mehrspaltiger Text ([#593](https://github.com/speedata/publisher/issues/593)).
- Fehlerkorrektur verschachtelte HTML Liste (ul/ol).

### 4.19.13 (1.7.2024)

- Fehlerkorrektur SavePages im zukünftigen Modus und Inhalt nach SavePages ([#592](https://github.com/speedata/publisher/issues/592)).

### 4.19.12 (25.6.2024)

- Fehlerkorrektur für Leerraum unterhalb von Image in Paragraph ([#591](https://github.com/speedata/publisher/issues/591)).
- Objekte die zu groß sind werden in Spalte 1 ausgegeben.

### 4.19.11 (23.6.2024)

- Mache weißen Hintergrund konfigurierbar ([#590](https://github.com/speedata/publisher/issues/590)).

### 4.19.10 (18.6.2024)

- Neue XPath Funktion für den Zugriff auf Längen ([#587](https://github.com/speedata/publisher/issues/587)).
- Neue Option für das Melden von überlangen Zeilen ([#588](https://github.com/speedata/publisher/issues/588)).
- Fehlerkorrektur für die Erkennung überlanger Zeilen.

### 4.19.9 (13.6.2024)

- Korrigiere Image/bleed=auto für unteren Rand ([#586](https://github.com/speedata/publisher/issues/586)).

### 4.19.8 (13.6.2024)

- Füge Sanskrit Trennmuster hinzu.
- Die PDF-Version ist nun 1.7 als Voreinstellung.
- Bessere Unterstützung für barrierefreies PDF.

### 4.19.7 (10.6.2024)

- Beachte jpeg Orientierung in eingebundenen Bildern ([#584](https://github.com/speedata/publisher/issues/584)).

### 4.19.6 (30.5.2024)

- Bessere Fehlermeldung für sd:decode-html().

### 4.19.5 (23.5.2024)

- Korrigiere Unterstreichen in sd:decode-html ([#581](https://github.com/speedata/publisher/issues/581)).

### 4.19.4 (22.5.2024)

- Erlaube das Setzen von /Creator mit `--suppressinfo` ([#577](https://github.com/speedata/publisher/issues/577)).

### 4.19.3 (15.5.2024)

- Setze PDF producer.
- Korrigiere sd:(keep-)alternating für den neuen XPath Parser.

### 4.19.2 (22.4.2024)

- Korrigiere autoopen im Fehlerfall.

### 4.19.1 (21.4.2024)

- Fehlerkorrektur: Farbe der Tabllenzeilien wenn keine Breite in den Spalten vorgegeben ist ([#576](https://github.com/speedata/publisher/issues/576)).
- Fehlerkorrektur: Value in Function.

### 4.19.0 (20.4.2024)

- Verbessere Function.

## 4.18

### 4.18.0 (19.4.2024)

- Veröffentliche Version 4.18.0.

## 4.17

### 4.17.24 (19.4.2024)

- Füge Testfall für SavePages hinzu.

### 4.17.23 (17.4.2024)

- Korrigiere Makeindex für neuen XPath-Modus.
- Optischer Randausgleich mit harfbuzz.

### 4.17.22 (12.4.2024)

- Verschiedene Fehlerkorrekturen: number(), While und interne Variablen im neuen XPath-Modus, einzelnes Leerzeichen im Harfbuzz Modus ([#570](https://github.com/speedata/publisher/issues/570), [#573](https://github.com/speedata/publisher/issues/573), [#574](https://github.com/speedata/publisher/issues/574)).

### 4.17.21 (27.3.2024)

- C-Bibliothek wieder einbauen, damit der speedata Publisher unter Windows funktioniert ([#570](https://github.com/speedata/publisher/issues/570)).

### 4.17.20 (21.3.2024)

- Verschiedene Korrekturen bzgl. Leerraum (Kerning bei Initialen, mehrfache non-breaking Leerräume im Harfbuzz-Modus, mehrfache 0-Breite Leerräumen (zws)).
- Fehlerkorrekturen für verschiedene Layoutfunktionen im lxpath Modus.

### 4.17.19 (18.3.2024)

- Korrigiere einige Layoutfunktionen bei lxpath.

### 4.17.18 (14.3.2024)

- HB Kerning wieder eingeschaltet wenn fontforge der voreingestellter Fontlader ist.

### 4.17.17 (13.3.2024)

- sdluatex binary lookup in der PATH Umgebungsvariable.
- CGO_C/LDFLAGS überschreiben wenn die sp Bibliothek kompiliert wird.

### 4.17.16 (6.3.2024)

- Setze den voreingestellten Harfbuzz Shaper auf "ot".
- Fehlerkorrektur Harfbuzz und Zeilenumbruch bei manchen Fonts ([#566](https://github.com/speedata/publisher/issues/566)).

### 4.17.15 (4.3.2024)

- Statusdatei wiederherstellen (Kompatibilität für den Server-Modus).
- Update der Bildverarbeitungsbibliothek (resize).

### 4.17.14 (3.3.2024)

- Lösche status-Datei, bessere Fehlerbehandlung/Exit Status.

### 4.17.13 (2.3.2024)

- Entferne die luaglue Bibliothek.
- Loglevel 'notice' ist zwischen info und warn.

### 4.17.12 (1.3.2024)

- Unicode links nach rechts und ähnliche Marker geben keine Warnung mehr ([#565](https://github.com/speedata/publisher/issues/565)).

### 4.17.11 (29.2.2024)

- Markdown Implementierung.
- Bild neuberechnen benötigt nicht mehr den Imageserver .

### 4.17.10 (19.2.2024)

- Neues Pro-Feature für on-the-fly Bilderneuberechnung (benötigt imageserver).
- Go/Lua XML Parser neu geschrieben (lxpath).

### 4.17.9 (12.2.2024)

- Fehlerkorrektur für $_lastpage im luxor XML Modus ([#561](https://github.com/speedata/publisher/issues/561)).

### 4.17.8 (29.1.2024)

- Verbessere Fehlermeldungen.

### 4.17.7 (18.1.2024)

- Bessere Ausgabe wenn der Publisher beendet wird.

### 4.17.6 (18.1.2024)

- Entferne Debugging-Nachricht.

### 4.17.5 (17.1.2024)

- Experimentelle Option "xmlfile", um XML Daten in eine Datei zu schreiben ([#557](https://github.com/speedata/publisher/issues/557)).

### 4.17.4 (11.1.2024)

- Fehlerkorrekturen im Zusammenhang mit harfbuzz/lxpath ([#556](https://github.com/speedata/publisher/issues/556)).

### 4.17.3 (11.1.2024)

- lxpath ist nun der voreingestellte XPath Parser.

### 4.17.2 (10.1.2024)

- Harfbuzz ist nun der voreingestellte Font-Loader.

### 4.17.1 (10.1.2024)

- Aktualisiere auf Go 1.21.
- speedata Publisher Ausgabe / logging vollständig verändert.

### 4.17.0 (8.1.2024)

- Neues Layout der ZIP Datei ohne Extra sdluatex Verzeichnis.

## 4.16

### 4.16.0 (7.1.2024)

- Veröffentliche Version 4.16.0.

## 4.15

### 4.15.21 (4.1.2024)

- Benenne backgroundcolor nach background-color bei verschiedenen Befehlen um ([#554](https://github.com/speedata/publisher/issues/554)).
- Rahmenfarbe '-' für keine Farbe bei Frame.
- Transparenz bei DefineColor und `value="..."`.
- Setze das voreingestellte Schema in catalog.xml auf RELAX NG.

### 4.15.20 (2.1.2024)

- Fehlerkorrektur: Zero width space ([#552](https://github.com/speedata/publisher/issues/552)).
- Logge Dateilookup bei Verbose > 0.

### 4.15.19 (23.12.2023)

- Fehlerkorrektur bei Span und Hintergrund ([#547](https://github.com/speedata/publisher/issues/547)).

### 4.15.18 (20.12.2023)

- Transparenz mit Frame/Rahmenfarbe ([#544](https://github.com/speedata/publisher/issues/544)).

### 4.15.17 (19.12.2023)

- Zeileninformation bei Message ([#545](https://github.com/speedata/publisher/issues/545)).
- Transparenz mit Frame ([#544](https://github.com/speedata/publisher/issues/544)).

### 4.15.16 (28.11.2023)

- Verschiedene Korrekturen für Metapost ([#542](https://github.com/speedata/publisher/issues/542), [#543](https://github.com/speedata/publisher/issues/543)).

### 4.15.15 (26.11.2023)

- Korrigiere diverse Fehler mit Transparenz ([#542](https://github.com/speedata/publisher/issues/542)).

### 4.15.14 (25.11.2023)

- Einige Fehlerkorrekturen bzgl. lxpath (DefineGraphic und ProcessNode).
- Schema Änderung (erlaube Overlay in Case).

### 4.15.13 (21.11.2023)

- Umbenennung von A/embed zu A/embedded.

### 4.15.12 (15.11.2023)

- Fehlerkorrektur Mark-Befehl mit dem neuen XPath parser.
- Neue Funktion `sd:dimexpr()`, um mit Einheiten zu rechnen.

### 4.15.11 (14.11.2023)

- Overlay: korrigiere Positionierung bei mehreren Kindern ([#520](https://github.com/speedata/publisher/issues/520)).
- Hyperlink auf eingebettete Dateien ([#522](https://github.com/speedata/publisher/issues/522)).
- Aktualisiere den lxpath XPath parser.

### 4.15.10 (8.11.2023)

- Erneute Fehlerkorrektur neuer XPath Parser ([#538](https://github.com/speedata/publisher/issues/538)).
- Neues Attribut require bei Layout.

### 4.15.9 (7.11.2023)

- Erweitere den neuen XPath parser mit For-Ausdruck.
- Fehlerkorrektur neuer XPath Parser ([#537](https://github.com/speedata/publisher/issues/537)).

### 4.15.8 (2.11.2023)

- Neuer XPath Parser ([#536](https://github.com/speedata/publisher/issues/536)).
- Das eigenständige HTML Subsystem entfernt.

### 4.15.7 (21.10.2023)

- Rahmenfarbe bei A ([#526](https://github.com/speedata/publisher/issues/526)).
- sp --ignore-case wieder eingebaut ([#534](https://github.com/speedata/publisher/issues/534)).
- Nicht gefundene Trennmuster geben eine Warnung anstelle eines Fehlers ([#532](https://github.com/speedata/publisher/issues/532)).

### 4.15.6 (18.10.2023)

- Fehlerkorrektur für URL Text ([#529](https://github.com/speedata/publisher/issues/529)).
- Erlaube Leerzeichen in imagehandler ([#527](https://github.com/speedata/publisher/issues/527)).

### 4.15.5 (10.10.2023)

- Neuer Metapost Befehl spcolor ([#524](https://github.com/speedata/publisher/issues/524)).
- Erlaube Kommentare in Variablen-Dateien ([#518](https://github.com/speedata/publisher/issues/518)).

### 4.15.4 (18.9.2023)

- MetaPost subsystem neu geschrieben und erweitert.

### 4.15.3 (7.9.2023)

- Weitere Unicode Leerzeichen hinzugefügt.

### 4.15.2 (18.8.2023)

- Warnung bei Bild nicht gefunden und nicht-letzter Option ([#514](https://github.com/speedata/publisher/issues/514)).

### 4.15.1 (16.8.2023)

- Neue Optionen für Seitenlayout bei PDFOptions.

### 4.15.0 (17.7.2023)

- Erlaube das Tracing-Raster obenauf zu sein ([#512](https://github.com/speedata/publisher/issues/512)).

## 4.14

### 4.14.0 (3.7.2023)

- Veröffentliche Version 4.14.

## 4.13

### 4.13.18 (6.6.2023)

- Fehlerkorrektur: border collapse und rowspan ([#482](https://github.com/speedata/publisher/issues/482)).
- Fehlerkorrektur. NoBreak kann nur ein Kind haben ([#455](https://github.com/speedata/publisher/issues/455)).
- Fehlerkorrektur: Span/padding und Leerraum am Anfang ([#506](https://github.com/speedata/publisher/issues/506)).

### 4.13.17 (5.6.2023)

- Fehlerkorrektur valign und halign bei PlaceObject ([#503](https://github.com/speedata/publisher/issues/503)).
- Fehlerkorrektur verfügbarer Raum mit Raster dy > 0 ([#505](https://github.com/speedata/publisher/issues/505)).

### 4.13.16 (2.6.2023)

- Fehlerkorrektur halign="right" mit Abstand im Raster ([#503](https://github.com/speedata/publisher/issues/503)).
- Warnung bei doppelten Dateieinträgen ([#501](https://github.com/speedata/publisher/issues/501)).
- Neue Syntax für Dateinamen, Seitenzahlen und PDF-Boxen in Bild-Funktionen ([#502](https://github.com/speedata/publisher/issues/502)).

### 4.13.15 (11.5.2023)

- Bugfix bei Options startpage.
- Fehlerkorrektur: Image bleed="auto" und Options trim nicht gesetzt.
- Konturschrift.

### 4.13.14 (4.5.2023)

- Fehlerkorrektur für *-Spalten in Tabellen und minwidth.
- Fehlerkorrektur für margin bei Image ([#491](https://github.com/speedata/publisher/issues/491)).
- Frame: Border-radius für alle vier Ecken bestimmen ([#492](https://github.com/speedata/publisher/issues/492)).

### 4.13.13 (20.4.2023)

- margin-* bei Image.
- Fehlerkorrektur colspan ([#481](https://github.com/speedata/publisher/issues/481)).

### 4.13.12 (27.3.2023)

- \r in Versionsdatei ([#486](https://github.com/speedata/publisher/issues/486)).
- Aktualisiere Abhängigkeiten.

### 4.13.11 (14.3.2023)

- Fehlerkorrektur für leere AUX-Dateien.

### 4.13.10 (10.3.2023)

- Spezielle Dateinamen mit Doppelpunkt-Syntax in Layoutfunktionen ([#468](https://github.com/speedata/publisher/issues/468)).
- B: # in URLs korrekt kodiert ([#472](https://github.com/speedata/publisher/issues/472)).
- Setze display mode nur bei Bedarf ([#470](https://github.com/speedata/publisher/issues/470)).

### 4.13.9 (27.2.2023)

- Neuer Wert bei Column `minwidth` und neue Schlüsselwörter für width (`min` und `max`).
- Neue XPath-Funktion `matches()` ([#453](https://github.com/speedata/publisher/issues/453)).
- Lösche Handbuch aus der ZIP-Datei.

### 4.13.8 (23.2.2023)

- Zwei neue Funktionen Seitenbreite und Seitenhöhe ([#464](https://github.com/speedata/publisher/issues/464)).

### 4.13.7 (22.2.2023)

- Fehlerkorrektur: kaputter hyperlink wird beim Kern eingesetzt ([#461](https://github.com/speedata/publisher/issues/461)).
- Korrigiere untere Radien bei Frame ([#459](https://github.com/speedata/publisher/issues/459)).

### 4.13.6 (20.2.2023)

- Umbenennung des Attributs graphics zu graphic bei Td ([#457](https://github.com/speedata/publisher/issues/457)).
- Entferne den Befehl NewPage vom Schema und der Dokumentation.
- Doppelpunkt-Syntax für die Angabe einer Seitennummer bei sd:aspectratio, sd:imagewidth und sd:imageheight ([#456](https://github.com/speedata/publisher/issues/456)).

### 4.13.5 (7.1.2023)

- Fehlerkorrektur für sd list-fonts ([#454](https://github.com/speedata/publisher/issues/454)).
- Fehlerkorrektur für URL-Rahmen und Bindestriche ([#499](https://github.com/speedata/publisher/issues/499)).
- Setze voreingestellten Mime-Typ für Attachments ([#451](https://github.com/speedata/publisher/issues/451)).

### 4.13.4 (22.11.2022)

- Fehlerkorrekturen Berechnung von Hashes und bei Anhängen ([#446](https://github.com/speedata/publisher/issues/446)).
- Fehlerkorrektur Stil bei Penalty ([#449](https://github.com/speedata/publisher/issues/449)).

### 4.13.3 (18.11.2022)

- Einige Fehlerkorrekturen bei AttachFile.

### 4.13.2 (10.11.2022)

- Vertikaler Versatz für Hyperlink-Anker.
- AttachFile kann nun andere Dateien neben ZUGFeRD Rechnungen anhängen.

### 4.13.1 (9.11.2022)

- Fehlerkorrektur im RTL-Modus ([#445](https://github.com/speedata/publisher/issues/445)).

### 4.13.0 (30.9.2022)

- Starte mit Pro-Paket.

## 4.12

### 4.12.0 (30.9.2022)

- Veröffentliche Version 4.12.0.

## 4.11

### 4.11.8 (6.9.2022)

- Suppressinfo erlaubt den PDF creator zu setzen ([#420](https://github.com/speedata/publisher/issues/420)).
- Neues Attribut displaymode für PDFOptions ([#428](https://github.com/speedata/publisher/issues/428)).
- Ausführung von SetVariable verzögern (optional) ([#412](https://github.com/speedata/publisher/issues/412)).
- Füge sd:sha256, sha512 und sd:md5 Funktionen hinzu ([#414](https://github.com/speedata/publisher/issues/414)).
- Setze Rahmenfarbe für Hyperlinks ([#416](https://github.com/speedata/publisher/issues/416)).

### 4.11.7 (25.8.2022)

- Korrigiere NoBreak innerhalb von Td ([#410](https://github.com/speedata/publisher/issues/410)).
- Verarbeite Kommandozeilenvariablen mit Schrägstrichen ([#411](https://github.com/speedata/publisher/issues/411)).
- Erlaube Unicode Zeichenketten in der Beschreibung von Anhängen ([#376](https://github.com/speedata/publisher/issues/376)).
- Korrigiere Kerning in gemischten fontforge / harfbuzz Absätzen ([#413](https://github.com/speedata/publisher/issues/413)).
- Korrigiere Leerzeichen am Ende des Absatzes ([#392](https://github.com/speedata/publisher/issues/392)).

### 4.11.6 (25.7.2022)

- Bessere Fehlerbehandlung für Dateisuche ([#407](https://github.com/speedata/publisher/issues/407)).

### 4.11.5 (15.7.2022)

- Methoden beim Befehl Clip umbenennen ([#405](https://github.com/speedata/publisher/issues/405)).

### 4.11.4 (12.7.2022)

- Fehlerkorrektur für URL escaping.

### 4.11.3 (12.7.2022)

- Neuer Befehl Clip um Kanten von Objekten abzuschneiden.

### 4.11.2 (8.7.2022)

- Verschiedene Fehlerkorrekturen, die durch die Migration weg von LuaJIT/FFI entstanden sind.

### 4.11.1 (7.7.2022)

- Entferne Abhängigkeit von LuaJIT/FFI.

## 4.10

### 4.10.0 (7.7.2022)

- Veröffentliche Version 4.10.

## 4.9

### 4.9.10 (7.7.2022)

- Fehlerkorrektur: Leerzeichen vor Zahl wird gelöscht ([#392](https://github.com/speedata/publisher/issues/392)).
- Fehlerkorrektur: Benannte Sprungmarken und nicht-ausgeglichene Klammern.

### 4.9.9 (6.7.2022)

- Filter: zeige Ausgabe bei runtime.execute.

### 4.9.8 (1.7.2022)

- Bildumrisse können nun per Bild angeschaltet werden.
- XML-Dekodierer für Lua-Filter.
- Fehlerkorrektur URL Darstellung mit Hyperlinks ([#381](https://github.com/speedata/publisher/issues/381)).

### 4.9.7 (27.6.2022)

- runtime.execute in der Lua Vorverarbeitung.

### 4.9.6 (22.6.2022)

- Nur Änderungen im Handbuch.

### 4.9.5 (17.5.2022)

- Fehlerkorrektur für langer Tabellenfuß auf der letzten Seite ([#268](https://github.com/speedata/publisher/issues/268)).

### 4.9.4 (12.5.2022)

- Bessere Korrektur für ZWJ ([#369](https://github.com/speedata/publisher/issues/369)).

### 4.9.3 (10.5.2022)

- Neue Kommandozeilenoption, um die PDF-Version zu setzen (`--pdfversion`).
- Fehlerkorrektur beim zero width joiner und Indischer Schriften ([#369](https://github.com/speedata/publisher/issues/369)).

### 4.9.2 (9.5.2022)

- Erlaubt es die Anwendung (creator) des Documents festzulegen.

### 4.9.1 (3.5.2022)

- Korrektur: PDFOptions überschreibt vorhergehende Einträge ([#367](https://github.com/speedata/publisher/issues/367)).
- Korrigiere Reihenfolge der Bookmarks bei InsertPages ([#366](https://github.com/speedata/publisher/issues/366)).

## 4.8

### 4.8.0 (2.5.2022)

- Veröffentliche Version 4.8.

## 4.7

### 4.7.13 (29.4.2022)

- Fehlerkorrektur: indent und br im HTML-Modus ([#302](https://github.com/speedata/publisher/issues/302)).
- Start-Attribut bei ol im HTML modus ([#311](https://github.com/speedata/publisher/issues/311)).
- Fehlerkorrektur: A href=".." und interaction="no" ([#362](https://github.com/speedata/publisher/issues/362)).

### 4.7.12 (28.4.2022)

- Fehlerkorrekturen (sd:group-height() und HTML Darstellung) ([#364](https://github.com/speedata/publisher/issues/364)).
- VSpace hat nun minheight und height Attribute.

### 4.7.11 (7.4.2022)

- Erlaube Farbe `-` in Tablerule.

### 4.7.10 (5.4.2022)

- Fehlerkorrektur Tabellensplit und rowsep/leading ([#361](https://github.com/speedata/publisher/issues/361)).

### 4.7.9 (1.4.2022)

- Fehlerkorrektur Transparenz und mehrseitige Tabellen ([#360](https://github.com/speedata/publisher/issues/360)).
- Pathrewrite wieder implementieren.

### 4.7.8 (24.3.2022)

- NextFrame verschiebt den Cursor in die erste Spalte ([#358](https://github.com/speedata/publisher/issues/358)).
- URL Escape hyperlinks.
- sd:decode-html() dekodiert alle HTML Entitäten.
- Fehlerkorrektur ul/ol unterschlägt den ersten Eintrag von li ([#357](https://github.com/speedata/publisher/issues/357)).

### 4.7.7 (2.3.2022)

- XML-Parser: DTD ignorieren ([#355](https://github.com/speedata/publisher/issues/355)).
- Schema: NoBreak zu ForAll, Case, Otherwise, Loop,... hinzufügen ([#356](https://github.com/speedata/publisher/issues/356)).

### 4.7.6 (21.2.2022)

- Hintergrundfarbe (Text) und Kerning ([#353](https://github.com/speedata/publisher/issues/353)).

### 4.7.5 (20.2.2022)

- Hintergrundfarbe und Mix von RTL/LTR Text ([#352](https://github.com/speedata/publisher/issues/352)).

### 4.7.4 (9.2.2022)

- Update auf Saxon 11.

### 4.7.3 (21.1.2022)

- Fehlerkorrektur beim Austausch von Unicode Zeichen im HTML Parser ([#350](https://github.com/speedata/publisher/issues/350)).

### 4.7.2 (7.1.2022)

- Fehlerkorrektur: Tabellenausgleich und minheight=1 ([#348](https://github.com/speedata/publisher/issues/348)).

### 4.7.1 (17.12.2021)

- Fehlerkorrektur: colspan > 1 und border-collapse ([#347](https://github.com/speedata/publisher/issues/347)).

## 4.6

### 4.6.0 (10.11.2021)

- Veröffentliche Version 4.6.

## 4.5

### 4.5.19 (4.11.2021)

- Verbesserte Fehlerhandhabung.

### 4.5.18 (2.11.2021)

- Setze DYLD_LIBRARY_PATH auf macOS.
- XPath-Modus auf Attribute beschränken, die nicht select oder test sind.

### 4.5.17 (26.10.2021)

- Setze die Anzahl der Durchläufe für den Server.

### 4.5.16 (26.10.2021)

- Verbosität des Servers erhöhen (`sp server --verbose`).

### 4.5.15 (20.10.2021)

- Neue Route für die REST API um in einem Request Daten zu senden und PDF zu empfangen.

### 4.5.14 (8.10.2021)

- NewPage ist veraltet, nutze ClearPage. Siehe [#345](https://github.com/speedata/publisher/issues/345) für Informationen.

### 4.5.13 (7.10.2021)

- Farbprofil in die Distribution einbinden ([#344](https://github.com/speedata/publisher/issues/344)).

### 4.5.12 (6.10.2021)

- Intern/Tablerule: ersetze gefülltes Rechteck durch PDF-Linie.
- Setze das Verhalten bei überschüssigem vertikalen Leerraum.

### 4.5.11 (23.9.2021)

- Farbige QR-Codes.

### 4.5.10 (13.9.2021)

- Zurück zum Lua-basierten XML-Leser.

### 4.5.9 (12.9.2021)

- Erlaube Br vor Image ([#342](https://github.com/speedata/publisher/issues/342))

### 4.5.8 (30.8.2021)

- Fehlerhaften Zeilenumbruch in HTML herausnehmen ([#340](https://github.com/speedata/publisher/issues/340)).

### 4.5.7 (25.8.2021)

- Fehlerkorrektur für selbstschließende HTML-Tags ([#339](https://github.com/speedata/publisher/issues/339)).
- Bessere Längenberechnung in XPath-Ausdrücken.

### 4.5.6 (16.7.2021)

- Neue Layoutfunktion `sd:tounit()` für Berechnungen mit Einheiten.
- PlaceObject keepposition="yes" mit absoluter Positionierung.

### 4.5.5 (6.7.2021)

- Datenzugriff bei SetGrid.

### 4.5.4 (2.7.2021)

- HSpace am Anfang des Textes ([#338](https://github.com/speedata/publisher/issues/338)).

### 4.5.3 (2.7.2021)

- Datenattribute für CSS-Style ignorieren ([#337](https://github.com/speedata/publisher/issues/337)).

### 4.5.2 (1.6.2021)

- Mehrfaches XInclude beim neuen XML-Parser.

### 4.5.1 (25.5.2021)

- Interne Änderungen (benannte Attribute, weitere CSS-ähnliche style-Namen).
- Neuer Go-basierter XML Prozessor.

## 4.4

### 4.4.1 (25.5.2021)

- Fehlerkorrektur für InsertPages ([#335](https://github.com/speedata/publisher/issues/335)).

### 4.4.0 (11.5.2021)

- Veröffentliche Version 4.4.

## 4.3

### 4.3.21 (11.5.2021)

- Warnung für Windows-Anwender und nicht-ASCII Verzeichnisnamen ([#310](https://github.com/speedata/publisher/issues/310)).

### 4.3.20 (4.5.2021)

- Fehlerkorrektur für mehrfache NewPage ([#334](https://github.com/speedata/publisher/issues/334)).

### 4.3.19 (3.5.2021)

- Fehlerkorrektur für InsertPages nach NewPage ([#333](https://github.com/speedata/publisher/issues/333)).

### 4.3.18 (27.4.2021)

- Bessere Implementierung von border-collapse ([#260](https://github.com/speedata/publisher/issues/260), [#332](https://github.com/speedata/publisher/issues/332)).

### 4.3.17 (26.4.2021)

- Verschiedene Fehlerkorrekturen ([#330](https://github.com/speedata/publisher/issues/330), [#331](https://github.com/speedata/publisher/issues/331), [#316](https://github.com/speedata/publisher/issues/316), [#317](https://github.com/speedata/publisher/issues/317)).

### 4.3.16 (16.4.2021)

- Neue Ausrichtung bei PlaceObject: hreference=center ([#327](https://github.com/speedata/publisher/issues/327)).
- Fehlerkorrektur NewPage openon="..." am Ende des Dokuments ([#329](https://github.com/speedata/publisher/issues/329)).
- Ausgabe der md5-Summe der XML-Dateien mit --verbose.

### 4.3.15 (15.4.2021)

- Neue PDFOption für Hyperlink Rahmen.
- Transparenz bei Text und Bildern.
- MetaPost Erweiterungen.

### 4.3.14 (24.3.2021)

- Ändere MetaPost Variablenanmen und füge page.* Variablen hinzu.
- Fehlerkorrektur bei `sd:file-exists()` und externen Ressourcen (noch einmal).

### 4.3.13 (23.3.2021)

- MetaPost CSS-Farben und Fehlerkorrekturen.
- Fehlerkorrektur bei `sd:file-exists()` und externen Ressourcen.

### 4.3.12 (16.3.2021)

- Fehlerkorrektur für Incscape auf Windows ([#324](https://github.com/speedata/publisher/issues/324)).
- Setze Sprache bei `Hyphenation` ([#319](https://github.com/speedata/publisher/issues/319)).

### 4.3.11 (16.3.2021)

- Fehlerkorrektur für Incscape auf Windows ([#324](https://github.com/speedata/publisher/issues/324)).
- Metapost Format in das Paket mit inkludieren.

### 4.3.10 (12.3.2021)

- Grundlegende MetaPost Funktionalität.

### 4.3.9 (10.3.2021)

- Bessere Fehlermeldung bei Problemen sdluatex zu starten.

### 4.3.8 (9.3.2021)

- Bild bei Bedarf vergrößern (maxwidth,maxheight gesetzt und stretch="yes") ([#321](https://github.com/speedata/publisher/issues/321)).

### 4.3.7 (8.3.2021)

- Fehlerkorrektur visible-pagenumbers ([#320](https://github.com/speedata/publisher/issues/320)).

### 4.3.6 (23.2.2021)

- Fehlerkorrektur Tabellenfuß ([#315](https://github.com/speedata/publisher/issues/315)).
- Go Quellcode-Organisation aufräumen.
- Hyperlinks für Image und Box.

### 4.3.5 (12.2.2021)

- Neue Variable für Seitenabschnitte (`_matter`).
- Fehlerkorrektur li/p ([#313](https://github.com/speedata/publisher/issues/313)).
- `sd:merge-pagenumbers()` mit Hyperlinks.
- Neue Layoutfunktion `sd:visible-pagenumber()`.
- Links zu Seiten (`&lt;A page="..."`).
- Dokumentenabschnitte (frontmatter, mainmatter) für unterschiedliche Seitennummerierung.
- Neue XPath-Funktion `sd:romannumeral()`.

### 4.3.4 (4.2.2021)

- Setze temporäres Verzeichnis im Server-Modus.

### 4.3.3 (20.1.2021)

- Leeres &lt;p&gt;-Tag im HTML Modus erzeugt eine leere Zeile ([#309](https://github.com/speedata/publisher/issues/309)).
- Fehlerkorrektur: Leerzeichen erzeugt eine leere Zeile in HTML ([#308](https://github.com/speedata/publisher/issues/308)).

### 4.3.2 (19.1.2021)

- Fehlerkorrektur für Leerzeilen durch leere Attribute ([#306](https://github.com/speedata/publisher/issues/306)).
- Unterstützung für mehrfache br-Tags in HTML ([#303](https://github.com/speedata/publisher/issues/303), [#305](https://github.com/speedata/publisher/issues/305)).
- Fehlerkorrektur für rowspan im Tabellenkopf ([#300](https://github.com/speedata/publisher/issues/300)).

### 4.3.1 (13.1.2021)

- `$_lastpage` beachtet letztes NewPage ([#299](https://github.com/speedata/publisher/issues/299)).
- Leerer Absatz erzeugt eine Leerzeile ([#297](https://github.com/speedata/publisher/issues/297)).
- Korrigiere Einrückung von UL/OL, setze fontfamily.
- Harfbuzz: Akzente Platzierung verbessern ([#296](https://github.com/speedata/publisher/issues/296), [#298](https://github.com/speedata/publisher/issues/298)).
- HTML: br in Elementen erlauben ([#293](https://github.com/speedata/publisher/issues/293)).
- HTML Parser: leere Elemente beachten.
- Windows 64 Bit Paket

## 4.2

### 4.2.0 (9.1.2021)

- Veröffentliche Version 4.2

## 4.1

### 4.1.25 (6.1.2021)

- Rückwärtsinkompatible Neuimplementierung des Befehls Initial ([#287](https://github.com/speedata/publisher/issues/287)).

### 4.1.24 (4.1.2021)

- Styling von li::before ([#286](https://github.com/speedata/publisher/issues/286)).
- Unterstreichen nach Bindestrich ([#291](https://github.com/speedata/publisher/issues/291)).
- Bookmark auf Ebene von PlaceObject ([#290](https://github.com/speedata/publisher/issues/290)).
- Fehlerkorrektur für falsche Zeilenhöhe ([#289](https://github.com/speedata/publisher/issues/289)).

### 4.1.23 (15.12.2020)

- Implementiere li::before für alternative Aufzählungspunkte. ([#286](https://github.com/speedata/publisher/issues/286))

### 4.1.22 (11.12.2020)

- Fehlerkorrektur: leerer String bei rechts-nach-links Texten ([#285](https://github.com/speedata/publisher/issues/285)).

### 4.1.21 (8.12.2020)

- Versionsinformation verschönern ([#284](https://github.com/speedata/publisher/issues/284)).
- Fehlerkorrektur für fehlerhafte Fontskalierung ([#283](https://github.com/speedata/publisher/issues/283)).

### 4.1.20 (7.12.2020)

- Fehlerkorrektur für dünne Linien in qrcodes ([#282](https://github.com/speedata/publisher/issues/282)).

### 4.1.19 (3.12.2020)

- Viele kleine Änderungen (Dokumentation und Reorganisation des Quellcodes).

### 4.1.18 (23.11.2020)

- Neue Option columndirection in Pagetype.
- Fehlerkorrektur für Initialen im rtl-Modus.
- Reorganisation der Go-Quelldateien, sp server in einem neuen Paket.

### 4.1.17 (18.11.2020)

- Korrekturen für bidi-Text/rechts-nach-links Text, Dokumentation Updates.

### 4.1.16 (13.11.2020)

- Fehlerkorrektur für background-color und Wortzwischenraum.

### 4.1.15 (12.11.2020)

- Einige Fehlerkorrekturen bei rechts-nach-links und gemischten ltr/rtl Texten.
- Fehlerkorrektur für rowspan in Tabellenköpfen ([#279](https://github.com/speedata/publisher/issues/279), [#280](https://github.com/speedata/publisher/issues/280)).
- Lösche den doctype Eintrag im XML Katalog (für einen Fehler in VSCode/XML-Modus).
- Fehlende Glyphen im harfbuzz Modus melden.

### 4.1.14 (30.10.2020)

- Automatisches NewPage vor SavePages (Modus zukünftige Seiten).
- Bidi-Algorithmus (experimentell).

### 4.1.13 (28.10.2020)

- Seitenbreite und Seitenhöhe bei Pagetype einstellbar.
- Fehlerkorrektur Farbe am Ende eines Absatzes ([#276](https://github.com/speedata/publisher/issues/276)).

### 4.1.12 (27.10.2020)

- Paragraph: Textrichtung einstellbar (experimentell).
- Fehlerkorrekturen im Harfbuzz-Modus.
- Fontlader ist per sp/config einstellbar.
- Höhere Auflösung für QA-Bilder.
- Schemakorrektur (Sprachen).

### 4.1.11 (22.10.2020)

- Verbesserte Akzenteplatzierung im harfbuzz-Modus (RTL).
- Fehlerkorrektur für Silbentrennung nach `&lt;br>` ([#274](https://github.com/speedata/publisher/issues/274)).
- Warnung bei `fontface` bei Textbefehlen (Paragraph, Textblock, Initial, Text, Barcode, Table, Nobreak). Dieser Befehl wird in Version 5 verschwinden.

### 4.1.10 (21.10.2020)

- Sprache in `Span` setzen ([#273](https://github.com/speedata/publisher/issues/273)).
- Erlaube Sprachcodes im XML Schema.
- Erste Vorbereitungen für rechts-nach-links Text.
- Schemakorrektur (erlaube XPath in Paragraph/language).
- Fehlerkorrektur textformat/margin bottom und border bottom ([#262](https://github.com/speedata/publisher/issues/262)).

### 4.1.9 (19.10.2020)

- Fehlerkorrektur Reihenfolge Bookmarks mit zukünftigen Seiten.
- Errate Sprache/Schreibsystem wenn nicht gesetzt (harfbuzz Modus).
- Spätes Laden von Schriftdateien.
- Fehlerkorrektur leerer erster Tabellenkopf und leerer letzter Tabellenfuß ([#271](https://github.com/speedata/publisher/issues/271)).
- Verbesserte Diagnoseinformation bei fehlgeschlagenem Serverlauf.

### 4.1.8 (13.10.2020)

- Fehlerkorrektur in Tabellenzellen ([#270](https://github.com/speedata/publisher/issues/270)).
- Kerning im harfbuzz modus, trace / kern.
- Ligaturen im harfbuzz-Modus ausschalten.
- Ersetze font CrimsonText durch CrimsonPro.

### 4.1.7 (7.10.2020)

- Grundlegende Unterstützung für verinfachtes Chinesisch. ([#204](https://github.com/speedata/publisher/issues/204))
- Korrigiere HTML Whitespace.

### 4.1.6 (5.10.2020)

- Verbessertes padding-left und padding right bei Paragraph.
- Kontrolle über vertikalen Leerraum im HTML Modus und in HTML-Daten.
- Harfbuzz Fontloader verbessert (mehr unterstützte Fonts).
- Sever temporäres Verzeichnis kann mit jedem Zeichen anfangen.

### 4.1.5 (1.10.2020)

- Zugriff auf Optionen während der Datenvorverarbeitung.

### 4.1.4 (1.10.2020)

- Fehlerkorrektur Reihenfolge der ol/ul li labels ([#246](https://github.com/speedata/publisher/issues/246)).
- Randnotizen links für Paragraph.

### 4.1.3 (28.9.2020)

- Korrigiere HTML ul/ol und li.
- Erlaube xinclude in Tabellenzellen ([#263](https://github.com/speedata/publisher/issues/263)).

### 4.1.2 (23.9.2020)

- Ein paar Fehlerkorrekturen und Verbesserungen (Barcode/keepfontsize)

### 4.1.1 (14.9.2020)

- Neuer Absatz-Zusammenbauer und neue HTML Verarbeitung, bessere Sprachunterstützung.

### 4.1.0 (8.9.2020)

- Fehlerkorrektur für Spracheinstellungen.

## 4.0

### 4.0.0 (7.9.2020)

- Veröffentliche stabile Version 4.0.0.

