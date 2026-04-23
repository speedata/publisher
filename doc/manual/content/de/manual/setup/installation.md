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
