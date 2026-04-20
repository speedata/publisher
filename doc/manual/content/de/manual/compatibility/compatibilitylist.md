---
title: "Kompatibilität mit anderer Software"
weight: 220
type: docs
---


Der speedata Publisher steht unter der AGPL (GNU Affero General Public License), die keine Gewährleistung für das Funktionieren einer Software vorsieht.
Trotzdem liegt es im Bestreben von speedata, dass die Software auf den gängigen Betriebssystemen läuft und mit externer Software problemlos zusammenspielt.

In diesem Abschnitt werden Erfahrungsberichte über die Kompatibilität zusammengefasst. Wenn hier etwas fehlt oder nicht stimmt, wird um Korrektur gebeten (info@speedata.de).

## Betriebssysteme

| Betriebssystem | Paket | Letzte Überprüfung | Publisher-Version | Notizen |
| --- | --- | --- | --- | --- |
| macOS 10.14.4 | ZIP | 2021-03-17 | 4.3.12 |  |
| Windows 7 64 bit | ZIP | 2021-03-17 | 4.3.12 |  |
| Windows Server 2012 R2 | ZIP | 2021-03-12 | 4.3.6 | (1) |
| Ubuntu (Docker) | ZIP | 2021-03-17 | 4.3.12 |  |
| Ubuntu 20.04.1 64 bit | Installer (development) | 2021-03-18 | 4.3.12 |  |


1. Zusätzliche Installation notwendig: Microsoft Visual C++ 2015-2019 Redistributable (x86) 14.24.28127, VCRuntime140.dll

## Externe Software

| Software | OS | Letzte Überprüfung | Publisher-Version | Bemerkung |
| --- | --- | --- | --- | --- |
| Inkscape 0.92 | Windows 7 64 bit | 2021-03-17 | 4.3.12 | (1) |
| Inkscape 1.0.2 | Windows 7 64 bit | 2021-03-17 | 4.3.12 | (2) |
| Inkscape 0.92 | macOS 10.14.6 | 2021-03-17 | 4.3.12 |  |


1. Konfiguration in `publisher.cfg` : `inkscape=C:\Program Files\Inkscape\bin\inkscape.com` und `inkscape-command=--export-pdf`.
2. Konfiguration in `publisher.cfg` : `inkscape=C:\Program Files\Inkscape\bin\inkscape.com` und `inkscape-command=--export-filename`.

## Dateiformate, Ausgabe

| Dateityp | Erlaubte Formate | Bemerkung |
| --- | --- | --- |
| Bilder | PDF, JPEG, PNG |  |
| Fonts | PostScript Type1, TrueType, OpenType (ttf, otf) | Ggf. unterstützen nicht alle Fontloader alle Formate. |
| PDF-Ausgabe | PDF/X-3, PDF/X-4, PDF/A-3, PDF/UA |  |
| ZUGFeRD | Version 1 und 2 |  |


## Bekannte Probleme

* Der Pfad der speedata Publisher-Installation auf Windows darf keine Umlaute enthalten. (Siehe Fehler [#310](https://github.com/speedata/publisher/issues/310).)
* Das Windows-Installationsprogramm begrenzt die Länge der PATH-Variable auf 1024 Zeichen (Siehe Fehler [#582](https://github.com/speedata/publisher/issues/582).)

