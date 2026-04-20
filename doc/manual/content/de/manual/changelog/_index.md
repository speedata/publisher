---
title: "Liste der Änderungen"
weight: 900
type: docs
---

## 5.5

### 5.5.8 (14.4.2026)

- Berücksichtige Box-Höhe in Zeilen (Zeilenhöhe).
- Box-Rahmen.
- Vertikale Ausrichtung für Box im Absatzmodus.
- Bilder: vertikale Ausrichtung im Absatz.
- Action-Befehl entfernt.
- Suppressinfo für Metadaten.
- Prüfsummenunterschied in sp compare anzeigen.
- Neues Attribut match bei Record.

### 5.5.7 (2.4.2026)

- Fehlerkorrektur Tabellenstauch-Algorithmus.

### 5.5.6 (2.4.2026)

- Fehlerkorrektur PDF copy/paste hyphen minus.

### 5.5.5 (1.4.2026)

- Korrigiere minimale Breite in Tabellen mit colspan und rowspan.
- Korrigiere CSS Vererbung bei td/tr.

### 5.5.4 (1.4.2026)

- HTML-Tabellen: beachte rowspan und colspan. Verhindere rowspan am Ende der Seite.

### 5.5.3 (9.3.2026)

- Servermodus: Endpunkt zum Abrufen der publisher-protocol.xml hinzugefügt.

### 5.5.2 (6.3.2026)

- Viele Rechtschreibkorrekturen in der Dokumentation.
- Barrierefreiheit für Output/Text ([#614](https://github.com/speedata/publisher/issues/614)).
- PDF/UA Strukturbaum.
- Korrektur PDF/UA und InsertPages / SavePages ([#613](https://github.com/speedata/publisher/issues/613)).
- Suchpfad hinzufügen, Dateien nicht duplizieren.
- Bessere Fehlermeldungen für Funktionsaufrufe und alten XPath-Parser.
- Fehlerkorrektur letter-spacing und Silbentrennung.
- Filter: Klassenpfad für Saxon korrekt setzen, einschließlich aller benötigten JAR-Dateien.

### 5.5.1 (2.3.2026)

- Fehlerkorrektur für Bildeinbindung (Transparenz), Attribut Kontext und Creator Version.

### 5.5.0 (26.2.2026)

- Fehlerkorrektur letter-spacing in Tabellen.

### 5.4.0 (24.2.2026)

- Veröffentliche stabile Version 5.4.

## 5.3

### 5.3.24 (23.2.2026)

- Neuer Befehl Section, um Layoutdateien zu organisieren (ohne Auswirkung auf Formatierung).

### 5.3.23 (19.2.2026)

- Fehlerkorrektur: ForAll behält Kontext.

### 5.3.22 (18.2.2026)

- Massive Geschwindigkeitsverbesserungen.
- Optischer Randausgleich Wert ist 1/1000 em.

### 5.3.21 (5.2.2026)

- Fehlerkorrektur: Silbentrennung funktioniert jetzt korrekt mit letter-spacing.

### 5.3.20 (29.1.2026)

- Fehlerkorrektur: Berechnung der verbleibenden Höhe in PlaceObject / absolute Positionierung.

### 5.3.19 (29.1.2026)

- Korrigiere Programmabbruch bei sp --help / --version.

### 5.3.18 (26.1.2026)

- Füge letter-spacing Attribut zu DefineTextformat hinzu (in 1/1000 em).
- Korrigiere Endlosschleife in post_linebreak.

### 5.3.17 (23.1.2026)

- Korrigiere Endlosschleife in HTML-Tabellen.
- Verbessere das Beenden von Kindprozessen in sp.

### 5.3.16 (20.1.2026)

- HTML-Tabellen mit nur Header oder Footer (leerer Body) werden jetzt korrekt ausgegeben.

### 5.3.15 (19.1.2026)

- Fehlerkorrektur für leere HTML-Tabellen.
- Implementiere Until für den neuen XPath-Parser.
- HTML-Verbesserungen (einschließlich Dokumentation).

### 5.3.14 (15.1.2026)

- HTML kann nun auf mehrere Seiten umbrechen.

### 5.3.13 (14.1.2026)

- Löse Endlosschleife in HTML-Tabellen.

### 5.3.12 (5.12.2025)

- Füge globale html-Option im Options-Befehl und --option html=off Kommandozeilen-Flag hinzu, um HTML-Parsing zu steuern.

### 5.3.11 (4.12.2025)

- Beschleunigt den Schriftsatz mit frühen Abbrüchen, gecachten Zugriffen und schlankerer Attributbehandlung in mknodes.
- Modularisiert publisher.lua in die Module color, links und metadata, um die Datei zu verkleinern.
- Aktualisiert qrencode auf die aktuelle Upstream-Version.

### 5.3.10 (30.11.2025)

- Behebt Verlangsamung im CSS/HTML-Rendering.

### 5.3.9 (25.11.2025)

- Ermögliche Textformaten, für HTML-Inhalte die in CSS definierte Schriftgröße zu verwenden.
- Korrigiere die Verarbeitung relativer (em) Schriftgrößen auf Basis der aktuellen Schriftgröße.
- Korrigiere die Darstellung von HTML-Rahmen im normalen Absatzmodus.
- Aktualisiere auf die neuste Saxon HE Version.
- Lösche Rust Quellcode.

### 5.3.8 (21.11.2025)

- Korrigiere HTML Border und currentcolor in Tabellenlinien.

### 5.3.7 (19.11.2025)

- HTML Border überarbeitet.
- Styles in HTML-Tabellen.

### 5.3.6 (11.11.2025)

- Fehlerkorrektur: UL-Zähler zurücksetzen.

### 5.3.5 (10.11.2025)

- Korrigiere @font-face in CSS (fataler Absturz).

### 5.3.4 (10.11.2025)

- HTML: Unterstützung für weitere Nummerierungsarten in Listen hinzugefügt (lower-alpha, upper-alpha usw.).
- Setze Exit-Code ungleich Null, wenn Fehler aufgetreten sind.
- Compare-Tool: Überarbeitung für mehr Stabilität und verbesserten HTML-Report (Prüfsummen, Build-Fehler, Vorschaubilder, Sortierung).
- HTML-zu-Lua-Rendering-Pipeline überarbeitet für strukturierte Ausgabe und klarere Trennung von CSS-Berechnung.

### 5.3.3 (4.11.2025)

- Führe alte Syntax mit geschweiften Klammern wieder ein bei Value/select und dem alten XPath parser ([#680](https://github.com/speedata/publisher/issues/680)) .
- Entferne die Rust-Bibliothek aus dem Build-Prozess ([#678](https://github.com/speedata/publisher/issues/678)).

### 5.3.2 (1.11.2025)

- Korrigiere Einrückung nach einem br.

### 5.3.1 (21.10.2025)

- Korrigiere Windows/Rust laden.

### 5.3.0 (21.10.2025)

- Alternative Rust-Bibliothek für dynamische Bindung.

## 5.2

### 5.2.0 (14.10.2025)

- Veröffentliche Version 5.2.

## 5.1

### 5.1.29 (14.10.2025)

- Go-XML-Parser tlw. neu geschrieben.

### 5.1.28 (5.10.2025)

- Korrigiere PDF-Metadaten / ISO-Datumsformat.

### 5.1.27 (4.10.2025)

- Fehlerkorrektur: XPath-Funktion doc() gibt den Wurzelknoten zurück statt des Dokumentknotens.

### 5.1.26 (23.9.2025)

- Neue XPath-Funktion translate().
- Dokumentation: Verwendung von px (Pixel) präzisiert.
- tabular.lua in ein Modul umgewandelt (interne Änderung).
- Absicherung für fehlenden Dateinamen in AttachFile.
- Neue XPath-Funktion distinct-values().

### 5.1.25 (15.9.2025)

- Publisher führt mehrere Läufe nun auch bei Fehlern aus.
- Unterstützung für japanischen Schriftsatz.
- Fehlerbehebung beim Fallback mit mehrzeichigen Sequenzen.

### 5.1.24 (15.9.2025)

- Warnung bei leerem Hyperlink.
- Verbesserte Fehlermeldung bei leerer Gruppe/Trace.
- Verbesserte Fehlermeldungen bei doppelten Dateien und Fehlern beim Schreiben der Aux-Datei.
- XPath: Neu: format-number() und round-half-to-even().
- Neuer Attributtyp „rawstring“ ohne {}-Maskierung.

### 5.1.23 (10.9.2025)

- Optionaler resizehandler für DPI-Einstellung (Konfigurationsdatei).
- CSS font-family darf nun mehrere Einträge haben.

### 5.1.22 (25.8.2025)

- Mehr HTML/CSS Features (Pseudoklassen, Padding in Tabellen und Rahmen).

### 5.1.21 (23.8.2025)

- NoBreak mit Hintergrundfarbe.
- NoBreak in Tabellenzellen ([#670](https://github.com/speedata/publisher/issues/670)).
- Fehlerkorrektur Bildkonvertierung mit gleichem Dateinamen und unterschiedlicher Dateiendung.
- Erweitere grundlegende HTML Eigenschaften (Eigene Schriftarten, Rahmen, rem-Größen).

### 5.1.20 (19.8.2025)

- Setze trapped auf false im PDF für Preflight.
- Schutzmaßnahmen gegen Go/Lua Thread-Fehler.

### 5.1.19 (18.8.2025)

- Erlaube Absatzform in Gruppen.
- Fehlerkorrektur: Datei löscht sich selbst beim kopieren ([#668](https://github.com/speedata/publisher/issues/668)).
- PDF Producer Eintrag in Metadaten.

### 5.1.18 (1.8.2025)

- Fehlerkorrektur: PlaceObject/rotate und vreference.

### 5.1.17 (30.7.2025)

- Fehlerkorrektur lxpath Modus und neuer XPath Parser.
- HTML Modus neu implementiert.
- Log-Level im Server-Modus.

### 5.1.16 (15.7.2025)

- Korrigiere sd:format-number ([#664](https://github.com/speedata/publisher/issues/664)).

### 5.1.15 (14.7.2025)

- Korrekte XML-Kodierung von Metadaten bei ZUGFeRD Anhängen.

### 5.1.14 (10.7.2025)

- Fehlerkorrektur HTML und großgeschriebene Tags.

### 5.1.13 (3.7.2025)

- Ignoriere DEL (Dezimal 127) Zeichen in der Eingabe ([#663](https://github.com/speedata/publisher/issues/663)).

### 5.1.12 (25.6.2025)

- Korrigiere (XPath)-Boolean-Wert von Attributen.

### 5.1.11 (18.6.2025)

- Kein fataler Fehler wenn ein Http-Bild fehlt.

### 5.1.10 (6.6.2025)

- Bessere Log-Meldungen.
- Neue XPath-Funktion sd:symbol() um eine Glyph-ID einzugeben.
- Lösche alte XPath-Dokumentation.

### 5.1.9 (23.5.2025)

- Neue Option 'addlocalpath' in der Konfigurationsdatei, damit das Arbeitsverzeichnis nicht rekursiv durchsucht wird.
- Neue Option mpcolorwarning um die Farb-Warnungen von MetaPost zu zeigen (Voreinstellung ist 'true') .

### 5.1.8 (22.5.2025)

- Fehlerkorrektur Layoutfunktion sd:current-framenumber() und neuer XPath parser.

### 5.1.7 (18.5.2025)

- cache=none funktioniert auch bei SVG Konvertierung ([#622](https://github.com/speedata/publisher/issues/622)).

### 5.1.6 (15.5.2025)

- Neuer Befehl `sp checkversion`, um auf Aktualisierungen zu prüfen ([#660](https://github.com/speedata/publisher/issues/660)).

### 5.1.5 (5.5.2025)

- Aktualisiere auf neue LuaTeX binaries (1.22.0).
- Ändere Systemfonts-Verzeichnissuche für Windows.

### 5.1.4 (5.5.2025)

- Fehlerkorrektur: Tabellenumbruch in AtPageShipout ([#659](https://github.com/speedata/publisher/issues/659)).
- Absolute Positionierung innerhalb einer Gruppe.

### 5.1.3 (7.4.2025)

- Korrigiere Leerzeichen im imagehandler.

### 5.1.2 (7.4.2025)

- Ändere die Breite und Höhe für vertikale Linien. Sollte keine Auswirkungen auf das Erscheinungsbild haben.

### 5.1.1 (7.4.2025)

- Lua Präprozessor: runtime.execute liefert den Erfolg bzw. den Exit-Code zurück.

### 5.1.0 (4.4.2025)

- Setze Hintergrundfarbe für jede Seite.

## 5.0

### 5.0.2 (4.4.2025)

- Fehlerkorrektur: Dateiname image hander bei automatischer Umwandlung.

### 5.0.1 (1.4.2025)

- Fehlerkorrektur: Rundungsfehler in manchen Rasterkonfigurationen.

### 5.0.0 (11.3.2025)

- Veröffentliche Version 5.0.

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

