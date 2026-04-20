---
title: "Visual Studio Code"
weight: 20
type: docs
---


Der kostenlose (und unter einer freien Lizenz stehende) Texteditor [Visual Studio Code](https://code.visualstudio.com) (kurz: VS Code) kann dank zahlreicher Extensions für sehr viele Programmiersprachen benutzt werden. Um das speedata Layout-Schema zu benutzen, wird die Extension „speedata Publisher" benötigt:

![Den Marktplatz für Erweiterungen öffnen und nach `speedata` suchen. Die Erweiterung „Speedata Publisher" installieren.](/img/vscode-speedata-extension.png)

Nach der Installation der Erweiterung werden Layoutdateien des speedata Publishers automatisch erkannt.
Eine manuelle Zuordnung zu einem Schema ist nicht mehr notwendig.
Die Erweiterung bietet Autovervollständigung und Validierung auf Basis von RELAX NG.

Hat alles geklappt, kommt bei einem Layout mit dem Namensraum `urn:speedata.de:2009/publisher/en` die Autovervollständigung mit Beschreibung:

![Autovervollständigung mit Kurzbeschreibung im Visual Studio Code.](/img/vscode-sample-layout.png)

