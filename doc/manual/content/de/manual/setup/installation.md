---
title: "Installationsanweisungen"
weight: 10
type: docs
---



{{< callout >}}
Den speedata Publisher kann man in zwei Versionen herunterladen: `stable` und `development`.
Beide Versionen sind problemlos zu benutzen.
Eine umfangreiche Qualitätssicherung verhindert, dass sich unentdeckt Fehler einschleichen.
In der Entwicklungsversion kann die Dokumentation dem aktuellen Stand hinterher sein.
Zum Ausprobieren lädt man sich in der Regel die Development-Version herunter.
Ebenso gibt es den speedata Publisher in zwei Paketen: Standard und Professional.
Die Professional-Variante hat zusätzliche Features, die im professionellen Umfeld für die Druckausgabe hilfreich sind.
{{< /callout >}}

Es gibt zwei Methoden, den Publisher zu installieren.

## Binärpakete (der empfohlene Weg)

Auf der [Download-Seite](https://download.speedata.de/) (https://download.speedata.de/) sind für macOS, Windows und GNU/Linux ZIP-Dateien zu finden, die man einfach extrahieren kann.
Dafür sind keine Administratorrechte notwendig.
Für Windows gibt es zusätzlich Installationspakete, die den Suchpfad korrekt setzen.
Damit ist in der Windows-Shell das Programm `sp.exe` überall aufrufbar.
Die aus dem ZIP extrahierte Struktur darf nicht verändert werden (z.B. verschieben des Binaries), der speedata Publisher erwartet das vorgegebene Dateilayout.
Nur hier kann das Pro-Paket heruntergeladen werden.

## Aus den Quellen bauen

Wer den Publisher selbst kompilieren möchte, findet die Anleitung in [BUILDING.md](https://github.com/speedata/publisher/blob/develop/BUILDING.md) im GitHub-Repository.
