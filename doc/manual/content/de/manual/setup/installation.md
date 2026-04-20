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

Es gibt drei Methoden, den Publisher zu installieren.

## Binärpakete (der empfohlene Weg)

Auf der [Download-Seite](https://download.speedata.de/) (https://download.speedata.de/) sind für macOS, Windows und GNU/Linux ZIP-Dateien zu finden, die man einfach extrahieren kann.
Dafür sind keine Administratorrechte notwendig.
Für Windows gibt es zusätzlich Installationspakete, die den Suchpfad korrekt setzen.
Damit ist in der Windows-Shell das Programm `sp.exe` überall aufrufbar.
Die aus dem ZIP extrahierte Struktur darf nicht verändert werden (z.B. verschieben des Binaries), der speedata Publisher erwartet das vorgegebene Dateilayout.
Nur hier kann das Pro-Paket heruntergeladen werden.

## APT Repository

Falls Administratorrechte auf einem Debian oder Ubuntu GNU/Linux System vorhanden sind, kann man einfach die `.deb`-Datei installieren. Hinweis: es wird bis auf weiteres nur die 64-Bit Plattform unterstützt.

Füge den GPG-Schlüssel von uns hinzu, damit du sicherstellst, dass du immer die richtige Software bekommst:

```
# alles in einer Zeile:
curl -fsSL
   http://de.speedata.s3.amazonaws.com/gpgkey-speedata.txt
   | sudo gpg --dearmor
   -o /usr/share/keyrings/speedata_de.gpg
```

Erstelle die Datei `/etc/apt/sources.list.d/speedata.list` mit dem Inhalt (Entwicklungsversion - development):

```
deb
   [arch=amd64 signed-by=/usr/share/keyrings/speedata_de.gpg]
   https://software.speedata.de/download/devel stable main
```

oder für die stabile Version:

```
deb
   [arch=amd64 signed-by=/usr/share/keyrings/speedata_de.gpg]
   https://software.speedata.de/download/public stable main
```

{{< callout >}}
Die letzten drei Beispiele müssen in einer Zeile eingegeben werden.
{{< /callout >}}

Nun kann man mit `sudo apt update` und `sudo apt install speedata-publisher` den Publisher installieren.

## Aus den Quellen bauen

Wer den Publisher selbst kompilieren möchte, findet die Anleitung in [BUILDING.md](https://github.com/speedata/publisher/blob/develop/BUILDING.md) im GitHub-Repository.
