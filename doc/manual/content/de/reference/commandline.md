---
title: "Starten des Publishers auf der Kommandozeile"
linkTitle: "Kommandozeile"
weight: 30
type: docs
---


Der speedata Publisher wird über die Kommandozeile (auch: Terminal, Befehlsfenster) gestartet.
Einerseits gibt es _Befehle_, anderseits lassen sich die Befehle über _Parameter_ steuern.


```shell
$ sp <Befehl>  <Parameter> <Parameter> ...
```

{{< callout >}}
Unter Windows/PowerShell muss man `sp.exe` angeben, da `sp` ein interner Befehl der PowerShell ist.
{{< /callout >}}

Der Standardbefehl ist `run`. So ist der Aufruf von

```shell
$ sp
```

dasselbe wie

```shell
$ sp run
```

Neben dem Befehl `run` gibt es noch weitere Befehle (s.u.).

Mit

```shell
$ sp --help
```

kann man sich eine Liste der erlaubten Befehle und Parameter ausgeben lassen.

## Erklärung der Befehle

`clean`
: Löscht alle generierten Zwischendateien und behält die PDF-Datei.

`clearcache`
: Löscht den Bildcache.

`checkupdate`
: Prüft, ob eine neue Version des Publishers verfügbar ist. Rückgabecode ist 0, wenn die Version aktuell ist. 1, wenn eine neue Version verfügbar ist.

`compare`
: Vergleicht PDF-Dateien für die Qualitätssicherung. Siehe [Qualitätssicherung]({{% relref "qualityassurance" %}}).

`doc`
: Zeigt das Handbuch im Browser an. Liegt der Installation das Handbuch bei (Verzeichnis `share/doc`), wird es über einen lokalen Webserver ausgeliefert; die Adresse erscheint auch auf der Konsole, der Server läuft bis Strg-C. Geöffnet wird die deutsche oder die englische Ausgabe, je nach Spracheinstellung des Systems (Umgebungsvariablen `LC_ALL`, `LC_MESSAGES`, `LANG`). Mit `--no-autoopen` wird der Browser nicht geöffnet. Ohne lokales Handbuch öffnet der Befehl die Online-Dokumentation auf <https://doc.speedata.de>, ebenfalls in der passenden Sprache.

`list-fonts`
: Listet alle Schriftdateien auf, die in den Publisher-Verzeichnissen gefunden werden. Zusammen mit `--xml` erlaubt dieses Kommando die Ausgabe per Copy&Paste in das Layoutregelwerk zu übernehmen. Siehe [Schriften verwenden]({{% relref "fonts" %}}).

`new [VERZEICHNIS]`
: Erstellt ein einfaches Gerüst (`layout.xml` und `data.xml`) für einen Publishing-Lauf im aktuellen Verzeichnis, sofern kein anderes angegeben ist.

`run`
: Startet den Publisher Lauf. Das ist die Voreinstellung, so dass das Kommando `sp` reicht, um den Publikationsprozess zu starten.

`server`
: Startet im Servermodus. Siehe [den Abschnitt Servermodus]({{% relref "servermode" %}}).

`watch`
: Startet den internen Hotfolder. Siehe [Publisher über Hotfolder starten]({{% relref "hotfolder" %}}).

## Erklärung der Kommandozeilenparameter

Die meisten Parameter entsprechen einem Schlüssel in der Konfigurationsdatei und sind auf der Seite [Konfiguration]({{< relref "configuration" >}}) beschrieben.
Die folgende Tabelle ordnet die Parameter den Schlüsseln zu; Angaben auf der Kommandozeile haben Vorrang vor der Konfigurationsdatei.

| Parameter | Konfigurationsschlüssel |
| --- | --- |
| `--address=IPADRESSE` | `address` (Abschnitt `server`) |
| `--autoopen` | `autoopen` |
| `--cache=METHODE` | `cache` |
| `--data=NAME` | `data` |
| `--dummy` | `dummy` |
| `-x`, `--extra-dir=DIR` | `extra-dir` |
| `--extra-xml=NAME` | `extraxml` |
| `--filter=FILTER` | `filter` |
| `--grid`, `--no-grid` | `grid` |
| `--ignore-case` | `ignore-case` |
| `--imagecache=PFAD` | `imagecache` |
| `--inkscape=PFAD` | `inkscape` |
| `--jobname=NAME` | `jobname` |
| `--layout=NAME` | `layout` |
| `--[no]-local` | `addlocalpath` |
| `--logfile=NAME` | `logfile` (Abschnitt `server`) |
| `--loglevel=LVL` | `loglevel` |
| `--mode=NAME[,NAME…]` | `mode` |
| `--pdfversion=VERSION` | `pdfversion` |
| `--port=PORT` | `port` (Abschnitt `server`) |
| `--runs=NUM` | `runs` |
| `--startpage=NUM` | `startpage` |
| `--systemfonts` | `systemfonts` |
| `--tempdir=DIR` | `tempdir` |
| `--timeout=SEK` | `timeout` |
| `-v`, `--var=VAR=WERT` | `vars` |
| `--verbose` | `verbose` |
| `--wd=DIR` | `wd` |
| `--xpath=PARSER` | `xpath` |

Die folgenden Parameter gibt es nur auf der Kommandozeile:

`-c, --config=NAME`
: Liest die angegebene Konfigurationsdatei ein. Voreinstellung ist `publisher.cfg`.

`--credits`
: Zeigt credits an und beendet das Programm.

`--[no]-cutmarks`
: Zeigt die Schnittmarken an. Einstellbar im [Layout (Befehl Options)]({{% relref "/reference/commands/options" %}}).

`--generate-completion=SHELL`
: Gibt ein Shell-Vervollständigungs-Skript (`bash`, `zsh` oder `fish`) auf der Standardausgabe aus und beendet das Programm. Siehe Abschnitt _Shell-Vervollständigung_ weiter unten.

`--mainlanguage=NAME`
: Bestimmt die Hauptsprache des Dokuments für die Silbentrennung. Mögliche Werte sind: `af`, `as`, `bg`, `ca`, `cs`, `cy`, `da`, `de`, `el`, `en`, `en_GB`, `en_US`, `eo`, `es`, `et`, `eu`, `fi`, `fr`,`ga`, `gl`, `gu`, `hi`, `hr`, `hu`, `hy`, `ia`, `id`, `is`, `it`,`ku`, `kn`, `la`, `lo`, `lt`, `ml`, `lv`, `ml`, `mn`, `mr`, `nb`, `nl`, `nn`, `or`, `pa`, `pl`, `pt`, `ro`, `ru`, `sa`, `sk`, `sl`,`sr`, `sv`, `ta`, `te`, `tk`, `tr`, `uk` und `zh`. Siehe [Codeliste der Sprachen](http://www.loc.gov/standards/iso639-2/php/code_list.php).

`--option=OPTION`
: Setze Optionen, die keine eigenen Kommandozeilenparameter haben.

`--outputdir=VERZEICHNIS`
: Die resultierende PDF-Datei und Protokolldatei wird in das angegebene Verzeichnis kopiert. Das Verzeichnis wird erstellt, falls es noch nicht existiert.

`--progress`
: Zeigt Fortschrittsinformationen auf der Standardausgabe an. Während des Publishing-Laufs werden die aktuelle Seitenzahl und die verstrichene Zeit angezeigt. Wurde der Publisher zuvor bereits ausgeführt, werden auch die erwartete Gesamtseitenzahl (aus dem vorherigen Lauf) und die vorherige Laufzeit angezeigt. Diese Option deaktiviert `--verbose`.

`--quiet`
: Unterdrückt alle Ausgaben des Publishers.

`--show-gridallocation`
: Markiert die belegten Rasterzellen in Gelb. Doppelt belegte Zellen werden rot gekennzeichnet. Siehe den [Befehl `<Trace>`]({{% relref "/reference/commands/trace" %}}).

`-s`, `--suppressinfo`
: Unterdrücke optionale Informationen (Zeitstempel) und benutze eine festgelegte Dokumenten-ID.

`--trace`
: Gibt zusätzliche Ausgaben auf der Standardausgabe aus.

`--varsfile=NAME`
: Liest eine Datei ein, in der in jeder Zeile in der Form `variable=wert` Variablen definiert werden. Zeilen, die mit `#` anfangen, werden ignoriert. Siehe auch `-v`, `--var`.

`--xml`
: Die Ausgabe des Befehls `list-fonts` werden als (Pseudo-)XML dargestellt, um sie in das Layoutregelwerk zu übernehmen.

## Shell-Vervollständigung

`sp` kann Tab-Vervollständigungs-Skripte für `bash`, `zsh` und `fish` erzeugen. Das Skript wird auf die Standardausgabe geschrieben und in die von der Shell erwartete Datei umgeleitet.

Die Vervollständigung kennt alle Optionen und Befehle; für Optionen mit Parameter wird als Standardvorschlag eine Datei-Vervollständigung angeboten.

### Bash

Pro Benutzer (das Paket `bash-completion` muss installiert sein):

```shell
$ sp --generate-completion=bash > ~/.local/share/bash-completion/completions/sp
```

Systemweit (z.B. aus einem Distributionspaket): `/usr/share/bash-completion/completions/sp`.

### Zsh

Pro Benutzer, eine mögliche Einrichtung:

```shell
$ mkdir -p ~/.zsh/completions
$ sp --generate-completion=zsh > ~/.zsh/completions/_sp
```

Anschließend in `~/.zshrc` _vor_ dem Aufruf von `compinit` ergänzen:

```shell
fpath=(~/.zsh/completions $fpath)
```

Systemweite Ablageorte sind `/usr/share/zsh/vendor-completions/_sp` (Debian/Ubuntu) oder `/usr/share/zsh/site-functions/_sp`.

### Fish

Fish lädt Vervollständigungen automatisch aus dem User-Konfigurationsverzeichnis:

```shell
$ sp --generate-completion=fish > ~/.config/fish/completions/sp.fish
```

Systemweiter Pfad: `/usr/share/fish/vendor_completions.d/sp.fish`.

