---
title: "Version 5"
weight: 10
type: docs
aliases:
  - latest
---

## 5.5

### 5.5.9 (20.4.2026)

- Dokumentation: Umstellung auf Hugo, Struktur neu organisiert.
- Erlaube Textblock in Td für bessere Kontrolle bei Rotation.
- Unterstützung für CSS ::marker.<br>
  Das CSS-Pseudoelement ::marker wird nun für die Listengestaltung unterstützt, einschließlich eigener Inhalte und Farben.
- Bilder werden bei trace objects="yes" gezeichnet.
- Fehlerkorrektur HTML Rahmen Breitenberechnung.

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

## 5.4

### 5.4.3 (4.3.2026)

- Fehlerkorrektur letter-spacing und Silbentrennung.
- Bessere Fehlermeldungen für Funktionsaufrufe und alten XPath-Parser.
- Filter: Klassenpfad für Saxon korrekt setzen, einschließlich aller benötigten JAR-Dateien.

### 5.4.2 (27.2.2026)

- Fehlerkorrektur Attribut Kontext.
- Fehlerkorrektur Bildeinbindung (Transparenz).
- Fehlerkorrektur Creator/Producer Version in PDF-Metadaten.

### 5.4.1 (26.2.2026)

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

