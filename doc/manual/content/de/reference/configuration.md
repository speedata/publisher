---
title: "Konfiguration des speedata Publishers"
linkTitle: "Konfiguration"
weight: 40
type: docs
---


Der Publisher ist auf verschiedene Weisen zu konfigurieren:

.  Die Datei `publisher.cfg` in `/etc/speedata/`, im Homeverzeichnis (mit Punkt davor) und im aktuellen Verzeichnis (Linux, Mac)
.  Die Datei `%APPDATA%\speedata\publisher.cfg` und im aktuellen Verzeichnis (Windows)
.  Die Parameter auf der Kommandozeile
.  Die Angaben in der Layoutdatei

## Die Konfigurationsdatei `publisher.cfg`

Die Datei `publisher.cfg` ist eine Datei, die beim Starten des Publishers eingelesen wird.
Es ist eine einfache Textdatei, die den Aufbau `Schlüssel = Wert` hat.

```
data      = data.xml
layout    = layout.xml
# Das ist ein Kommentar
# Das ist kein Kommentar
#  ^^^ das ist natürlich ein Kommentar, auch
#      wenn der Text anderes behauptet

# Spezifische Konfigurationswerte für
# einen Abschnitt
[Abschnitt]
key = value
```

In der Konfigurationsdatei kann mit `%(projectdir)s` auf das Verzeichnis
zugegriffen werden, in dem die Datei `publisher.cfg` liegt.
Die Variable gibt es nur in der Konfigurationsdatei. In den [Lua-Callbacks]({{% relref "/manual/integration/luacallbacks" %}}) wird sie nicht gebraucht: ein Dateiname, den der Callback `lookup_file` zurückgibt, wird von der regulären Dateisuche aufgelöst, die das Projektverzeichnis einschließt.

Alle Angaben in dieser Konfigurationsdatei sind optional.
Alle folgenden Konfigurationsdateien werden in dieser Reihenfolge eingelesen: `/etc/speedata/publisher.cfg`, `~/.publisher.cfg`
und im aktuellen Verzeichnis `publisher.cfg`.
Das aktuelle Verzeichnis kann beim Aufruf des Publishers mittels `--wd=...` geändert werden.

Das Format muss eingehalten werden, sonst wird die Datei nicht richtig
erkannt. Folgende Optionen werden unterstützt:

`autoopen` (Kommandozeile: `--autoopen`)
: Wenn hier `true` anstelle von `false` steht, wird das PDF nach dem Publisher-Durchlauf automatisch geöffnet.

`addlocalpath` (Kommandozeile: `--local`, `--no-local`)
: Wenn `true`, wird das aktuelle Verzeichnis rekursiv dem Suchpfad hinzugefügt. Voreinstellung ist `true`.

`cache` (Kommandozeile: `--cache`)
: Caching-Strategie für http(s) Dateien. Entweder `fast`, dann wird nur geschaut, ob die Datei im Dateisystem vorhanden ist oder `optimal`, dann wird bei jedem Zugriff auf die Datei geprüft, ob sie aktualisiert werden muss. Vollständig ausschalten kann man den Cache mit `none`. `none` funktioniert auch für SVG-Konvertierungen. In diesem Fall wird bei jedem Zugriff auf die Datei eine PDF-Datei erzeugt. Voreinstellung ist `optimal`.

`data` (Kommandozeile: `--data`)
: Name der XML-Daten. Wenn nicht vorhanden, wird die Datei `data.xml` geladen. Wird als Dateiname ein Strich (`-`) angegeben, liest der Publisher die XML-Daten von der Standardeingabe (STDIN). Es kann auch eine externe Ressource angegeben werden (`http://`).

`dummy` (Kommandozeile: `--dummy`)
: Wenn `true`, dann wird die Datendatei nicht eingelesen. Anstatt dessen wird der folgende Inhalt angenommen: `<data />`. Das dient zum einfachen Testen von Layoutregelwerken. Es muss also ein `<Record element="data">` im Layout vorhanden sein.

`extra-dir` (Kommandozeile: `-x`, `--extra-dir`)
: Ein Verzeichnis im Dateisystem, das Dateien für den Publisherlauf enthält. Dazu gehören die Schriftdateien, die XML-Dateien (Daten und Layoutregelwerk) sowie die einzubindenden Bilddateien. Sollen mehrere Verzeichnisse hinzugefügt werden, müssen diese mit `:` oder `;` getrennt werden, je nach Betriebssystem (Windows: `;`, alle anderen: `:`). Das aktuelle Verzeichnis wird automatisch eingebunden. Beispiel unter Windows: `extra-dir=c:\myfonts`. Auf der Kommandozeile kann der Parameter mehrfach angegeben werden.

`extensionhandler`
: Zuordnung von Dateiendungen zu in `imagehandler` definierten Konvertern. Um Grafiken on-the-fly zu konvertieren. Beispiel: `extensionhandler="mmd:mermaid"`. Mehrere Einträge werden mit Semikolon getrennt. Siehe auch `imagehandler`.

`filter` (Kommandozeile: `--filter`)
: Führt die angegebene Datei als Lua-Filter aus. Siehe Abschnitt [Lua-Filter / Vorverarbeitung]({{% relref "preprocessing" %}}).

`fontpath`
: Setzt den systemweiten Pfad für Fonts. Unter Windows ist dies `%WINDIR%\Fonts`, unter Mac OS X `/Library/Fonts:/System/Library/Fonts`.

`grid` (Kommandozeile: `--grid`, `--no-grid`)
: Bestimmt, ob das Raster angezeigt wird. Auch im Layout über den Befehl [`<Trace>`]({{% relref "/reference/commands/trace" %}}) einstellbar.

`hidespinfo`
: Wenn das auf 'true' gesetzt ist, wird der speedata Publisher die Information `(Created with the speedata Publisher - www.speedata.de)` nicht in die PDF Datei schreiben. Benötigt das Pro-Paket.

`imagecache` (Kommandozeile: `--imagecache`)
: Ordner für zwischengespeicherte Dateien (`file="http(s)://..."` und externe Programme). Voreinstellung: `$TMPDIR/sp/images`. Das Verzeichnis wird bei Bedarf erstellt.

`imagehandler`
: Zuordnungen von Bildtyp zu externen Konvertern, z.B. `imagehandler="mermaid:(/usr/bin/mmdc -i %%input%% -o %%output%%.pdf)"`. Mehrere Einträge werden mit Semikolon getrennt. Funktionsweise, Platzhalter und weitere Beispiele beschreibt der Abschnitt [Externe Konvertierungstools]({{% relref "/manual/imagesandgraphics#externe-konvertierungstools" %}}). Seit Version 5.9.2 ist der Lua-Callback `image_handler` die flexiblere Alternative, siehe [Lua-Callbacks]({{% relref "/manual/integration/luacallbacks" %}}).

`ignore-case` (Kommandozeile: `--ignore-case`)
: Ignoriere die Groß- und Kleinschreibung für Dateizugriff in der rekursiven Dateiliste.

`inkscape` (Kommandozeile: `--inkscape`)
: Pfad zum Inkscape-Programm.

`inkscape-command`
: Befehlszeile zur Bildkonvertierung. In Version 0.92 und vorher ist dies `--export-pdf` und ab Version 1 ist das `--export-filename`.

`jardir`
: Verzeichnis mit den Java-JAR-Dateien für XSLT- und RELAX-NG-Verarbeitung. Standardmäßig wird das mitgelieferte `lib`-Verzeichnis verwendet. Vor allem für Maintainer von Betriebssystem-Paketen relevant – siehe [System-eigene Java-JARs verwenden]({{% relref "installation#system-eigene-java-jars-verwenden" %}}).

`jobname` (Kommandozeile: `--jobname`)
: Name der Ausgabedatei ohne Dateiendung. Voreinstellung ist `publisher`.

`layout` (Kommandozeile: `--layout`)
: Name des Layoutregelwerks. `layout.xml` ist der voreingestellte Name. Es kann auch eine externe Ressource angegeben werden (`http://`).

`loglevel` (Kommandozeile: `--loglevel`)
: Setze die Logausgabe auf einen Level. Erlaubt ist `debug`, `info`, `message`, `warn` und `error`. Die Ausgaben in dem Level und darüber werden in der Protokolldatei ausgegeben.

`luafile` (Kommandozeile: `--luafile`)
: Lädt die angegebene Lua-Datei zu Beginn des Publishing-Laufs. Die Datei kann Callbacks für die Dateisuche und die Bildkonvertierung registrieren, siehe den Abschnitt [Lua-Callbacks]({{% relref "/manual/integration/luacallbacks" %}}). (Seit Version 5.9.2.)

`luatex`
: Pfad zum LuaTeX-Programm. Für Entwicklungszwecke.

`mode` (Kommandozeile: `--mode`)
: Setzt einen Modus für die Verarbeitung. Kann im Layout mit [`sd:mode()`]({{% relref "/reference/xpath/xpath" %}}) abgefragt werden. Mehrere Modi werden durch Komma getrennt angegeben. Siehe [Steuerung des Layouts]({{% relref "controllayout" %}}).

`opencommand`
: Kommando für das automatische Öffnen der Dokumentation bzw. PDF-Datei. Für MacOS X sollte das `open` sein, für Linux `xdg-open` oder `exo-open` (xfce).

`pathrewrite`
: Kommaseparierte Liste der Form Pfadteil=Pfadteil. Beispiel: `/media/=%(projectdir)s/myfiles/`. Das würde absolute Pfadangaben wie `file:///media/XYZ` in `file:///Pfad/zum/Projekt/myfiles/XYZ` ändern. Seit Version 5.9.2 ist der Lua-Callback `lookup_file` die flexiblere Alternative, siehe [Lua-Callbacks]({{% relref "/manual/integration/luacallbacks" %}}).

`pdfversion` (Kommandozeile: `--pdfversion`)
: Die Versionsnummer des PDFs, das geschrieben wird. Voreinstellung ist `1.7`.

`reportmissingglyphs`
: Sollen angeforderte aber fehlende Zeichen als Fehler oder als Warnung gemeldet werden? Die erlaubten Werte sind `true`, `false`, und `warning`. `false` schaltet die Ausgabe aus.

`resizehandler`
: Zuordnung von Bildtyp zu externen Konvertern, die die Bildgröße an die gewünschte DPI-Zahl anpassen. Z.B. `resizehandler="jpegimage:(magick %%input%% -resize %%width%%x%%height%%! %%output%%)"`. Siehe auch den Abschnitt [Konfiguration des Resizehandlers]({{% relref "/manual/imagesandgraphics#konfiguration-des-resizehandlers" %}}). (Seit Version 5.1.23.) Seit Version 5.9.2 ist der Lua-Callback `resize_handler` die flexiblere Alternative, siehe [Lua-Callbacks]({{% relref "/manual/integration/luacallbacks" %}}).

`runs` (Kommandozeile: `--runs`)
: Setzt die Anzahl der Durchläufe fest. Seit Version 5.9.4 kann die Anzahl auch im Layout mit dem Attribut `runs` bei `<Options>` angegeben werden. Die Kommandozeile hat Vorrang vor dem Layout, das Layout vor der Konfigurationsdatei.

`startpage` (Kommandozeile: `--startpage`)
: Nummer der ersten Seite.

`systemfonts` (Kommandozeile: `--systemfonts`)
: Lädt zusätzlich die Systemschriftarten. Funktioniert nicht unter Windows XP.

`tempdir` (Kommandozeile: `--tempdir`)
: Name des temporären Verzeichnisses. Voreinstellung ist die des Systems.

`timeout` (Kommandozeile: `--timeout`)
: Maximale Dauer des Publishing-Laufs. Wenn dieser Wert überschritten wird, bricht der Lauf mit Fehler 1 ab. Angabe in Sekunden.

`vars` (Kommandozeile: `-v`, `--var`)
: Kommaseparierte Liste der Form `var=wert`, um Variablen festzulegen. Auf der Kommandozeile setzt jedes `--var variable=wert` eine Variable und kann mehrfach angegeben werden, siehe auch `--varsfile`. Die Variablen können im Layout wie üblich mit `select="$variable"` benutzt werden.

`verbose` (Kommandozeile: `--verbose`)
: `true` gibt die Ausgaben der Protokolldatei auf Standardausgabe aus.

`wd` (Kommandozeile: `--wd`)
: Wechselt vor dem Start in das angegebene Verzeichnis, so als ob man vorher mit `cd` dorthin gewechselt hätte.

### Abschnitt Server (`server`)

`address` (Kommandozeile: `--address`)
: IP Adresse, auf die der Server den Port öffnen soll. Voreinstellung ist 127.0.0.1.

`extra-dir`
: Extra-Verzeichnisse für die aufzurufenden Publishing-Läufe.

`filter`
: Lua-Skript, das vor dem Verarbeiten der Publishing-Läufe ausgeführt werden soll (wie ein Aufruf `sp --filter ...`).

`logfile` (Kommandozeile: `--logfile`)
: Dateiname für das Protokoll. `STDOUT` für Standardausgabe und `STDERR` für Standardfehlerausgabe.

`loglevel`
: Setzt die Logausgabe auf einen Level. Erlaubt ist `debug`, `info`, `message`, `warn` und `error`.

`port` (Kommandozeile: `--port`)
: Port, zu dem eine Verbindung aufgebaut werden kann. Voreinstellung ist 5266.

`runs`
: Anzahl der Durchläufe für das Dokument.

### Abschnitt Hotfolder (`hotfolder`)

`hotfolder`
: Verzeichnis, das »beobachtet« werden soll.

`events`
: Regeln, welche Programme bei welchen Dateien ausgeführt werden sollen.

Eine genaue Beschreibung ist im Abschnitt [Publisher über Hotfolder starten]({{< relref "hotfolder" >}}) zu finden.

## Parameter auf der Kommandozeile

Die erlaubten Parameter auf der Kommandozeile werden im Abschnitt über die [Kommandozeile]({{< relref "commandline" >}})  aufgeführt.

## Angaben in der Layoutdatei

Das Layoutregelwerk erlaubt manche Parameter zu setzen. Dazu gehören die Angaben, die im Element [Options]({{< relref "/reference/commands/options" >}}) gesetzt werden.

