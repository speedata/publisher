title: speedata Publisher Installationsanleitung
---

# Wie installiere ich den speedata Publisher?

Es gibt drei Methoden, den Publisher zu installieren.

1. **Binärpakete** (der empfohlene Weg): Auf der [Downlaod-Seite](https://download.speedata.de/publisher/) sind für Mac, Linux und Windows ZIP-Dateien zu finden, die man einfach extrahieren kann. Dafür sind keine Adminstratorrechte notwendig. Für Windows gibt es zusätzlich Installationspakete, die den Suchpfad korrekt setzen. Damit ist in der Windows-Shell das Programm `sp` überall aufrufbar.

1. **APT Repository**: Falls Administratorrechte auf einem Debian oder Ubuntu GNU/Linux System vorhanden sind, kann man einfach die `.deb`-Datei installieren. Die Anweisungen hierzu [finden sich im Wiki](https://github.com/speedata/publisher/wiki/Linux-packages).

3. **Aus den Quellen installieren**: Für die Entwickler, die am Publisher selbst Änderungen vornehmen möchten: Die Software und die Dokumentation kann aus dem Quellcode gebaut werden mithilfe des Befehls `rake`. Notwendig dafür sind die üblichen Entwicklungswerkzeuge und die [Programmiersprache Go](https://golang.org/) in Version 1.5 oder höher. Auf einem Debian oder Ubuntu GNU/Linux System kann man folgende Befehle nutzen:


```
sudo apt install build-essential git rake golang
git clone https://github.com/speedata/publisher.git
cd publisher
rake build
rake doc
```

(Die Version von Go auf Debian jessie ist 1.3.3, die vermutlich nicht geeignet ist, um den Publisher zu bauen. Die aktuelle Version 1.6.3 kann auf diesem System installiert werden mit:
```
sudo apt install -t jessie-backports golang
```
sofern das Repository `jessie-backports` in  `/etc/apt/sources.list` aktiviert wird).

Falls der speedata Publisher aus den Quellen gebaut wird, muss noch LuaTeX hinzugefügt werden. Der vorgeschlagene Weg ist, unter <https://download.speedata.de/extra/> die Binärpakete zu laden und das passende Paket in das bin-Verzeichnis zu kopieren. Beispielsweise um LuajitTeX 0.79.1 auf einem Linux AMD64 System zu nutzen kann man die folgenden Befehle nutzen:

```
wget https://download.speedata.de/extra/luatex_079-win-mac-linux.zip
unzip luatex_079-win-mac-linux.zip
cp luatex/linux/amd64/0_79_1/sdluatex bin
```

Nach der Installation kann man `bin/sdluatex --version` aufrufen, um zu überprüfen, ob es die richtige Version ist.

