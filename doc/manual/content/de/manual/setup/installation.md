---
title: "Installationsanweisungen"
weight: 10
type: docs
---

Den speedata Publisher gibt es als fertiges Binärpaket für macOS, Windows und GNU/Linux.
Er kann in zwei Varianten heruntergeladen werden: Standard und Professional.
Die Professional-Variante bietet zusätzliche Features für die professionelle Druckausgabe.

## Stable oder Development?

Auf der [Download-Seite](https://download.speedata.de/) stehen jeweils zwei Versionslinien zur Auswahl:

- Stable: Getestet und bewährt. Diese Version eignet sich für den produktiven Einsatz.
- Development: Enthält immer die neuesten Features. Durch neue Funktionalität können vereinzelt Fehler auftreten, die erst einige Versionen später auffallen. Wer neue Features zeitnah nutzen möchte, greift zur Development-Version.

![Die Download-Seite](/img/download-page.png)

## Installation

Auf der [Download-Seite](https://download.speedata.de/) die passende ZIP-Datei für das eigene Betriebssystem herunterladen und an einem beliebigen Ort entpacken.
Administratorrechte sind dafür nicht notwendig.

{{< callout type="warning" >}}
Die entpackte Verzeichnisstruktur darf nicht verändert werden — der speedata Publisher erwartet das vorgegebene Dateilayout.
{{< /callout >}}

Für Windows gibt es zusätzlich Installationspakete (.exe), die den Suchpfad automatisch setzen.
Damit ist `sp.exe` direkt in der Kommandozeile verfügbar.

Auf macOS und Linux muss das `bin`-Verzeichnis aus dem entpackten Archiv manuell zum `PATH` hinzugefügt werden, oder man ruft `sp` mit dem vollständigen Pfad auf.

{{< callout >}}
Wer den Publisher selbst aus den Quellen kompilieren möchte, findet die Anleitung in [BUILDING.md](https://github.com/speedata/publisher/blob/develop/BUILDING.md) im GitHub-Repository.
{{< /callout >}}

## System-eigene Java-JARs verwenden

Der Publisher liefert drei Java-Archive im `lib`-Verzeichnis mit:

| Datei | Verwendung |
| --- | --- |
| `saxon-he-‹version›.jar` | XSLT-Prozessor, wird von `runtime.run_saxon()` für die [XSLT-Vorverarbeitung]({{% relref "preprocessing" %}}) genutzt |
| `xmlresolver-‹version›.jar` + `xmlresolver-‹version›-data.jar` | Katalog-Resolver, wird zusammen mit Saxon geladen |
| `jing.jar` | RELAX-NG-Validator, wird von `runtime.validate_relaxng()` genutzt |

Für die meisten Anwender funktionieren die mitgelieferten JARs ohne weitere Einstellungen.

Dieser Abschnitt ist vor allem für Maintainer von Betriebssystem-Paketen (FreeBSD, NixOS, …) relevant, deren Distributionsrichtlinien das Linken auf systemweite JARs verlangen statt eines privaten Mitlieferns.

### Die Konfigurationsoption `jardir`

Die Option [`jardir`]({{% relref "configuration" %}}) zeigt auf ein Verzeichnis, in dem die JARs flach (ohne `lib/`-Unterverzeichnis) abgelegt sind. Der Publisher sucht dann:

- `‹jardir›/jing.jar`
- `‹jardir›/saxon-he-*.jar` (beliebige Version, die zum Glob passt)
- `‹jardir›/xmlresolver-*.jar`

Die Saxon-JAR wird per Glob gematcht, nicht über einen exakten Dateinamen, daher muss die System-Version nicht mit der mitgelieferten Version übereinstimmen. Kompatibilität innerhalb der Saxon-12.x-Reihe ist zu erwarten; eine andere Major-Version kann je nach API-Änderungen funktionieren oder nicht.

### `jardir` setzen

Die Option lässt sich an drei Stellen setzen:

1. Pro Aufruf auf der Kommandozeile: `sp --option jardir=/usr/local/share/java/classes`
2. Projektlokal: in `publisher.cfg` im aktuellen Arbeitsverzeichnis.
3. Systemweit: in `/etc/speedata/publisher.cfg`:

   ```ini
   [DEFAULT]
   jardir = /usr/local/share/java/classes
   ```

Die systemweite Variante ist das, was ein Port- bzw. Paket-Maintainer typischerweise installiert.

### Beispiel: FreeBSD

Der Port `textproc/saxon-he` installiert:

```
/usr/local/share/java/classes/saxon-he-12.8.jar
/usr/local/share/java/classes/xmlresolver-5.3.3.jar
/usr/local/share/java/classes/xmlresolver-5.3.3-data.jar
```

und `textproc/jing` legt `jing.jar` ins gleiche Verzeichnis. Mit `jardir = /usr/local/share/java/classes` werden also Saxon, xmlresolver und jing gleichermaßen aus den Systempaketen bezogen.
