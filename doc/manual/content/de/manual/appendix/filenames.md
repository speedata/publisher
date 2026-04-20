---
title: "Dateinamen im Publisher"
weight: 20
type: docs
---



An verschiedenen Stellen im Layout, hauptsächlich bei den Bildern, werden externe Dateien referenziert.
Diese können folgende Formate haben:

* Absoluter Pfad im Dateisystem: `/pfad/zur/datei.png`.
* Relativer Pfad im Dateisystem: `../verzeichnis/datei.png`.
* Datei innerhalb des Suchbaums `datei.png`. Vor dem Start wird das aktuelle Verzeichnis rekursiv durchsucht (siehe [organisationdaten]({{< relref "fileorganization" >}})).
* Absolute Pfade unter Windows wie `c:\Users\....\datei.png`.
* file-Schema: `file://c/Users/Joe%20User/datei.png` oder `file:///home/user/datei.png`.
* http-Schema: `http://picsum.photos/400/300` oder https: `https://picsum.photos/400/300` ([Pro Feature]({{< relref "speedatapro" >}}))

Diese Dateinamen können bei [Bildern]({{< relref "/reference/image" >}}), bei [XPath- und Layoutfunktionen]({{< relref "xpath" >}}) sowie auf der Kommandozeile benutzt werden.
So ist es möglich, den Publisher mit

```sh
sp --dummy --data https://raw.githubusercontent.com/speedata/examples/master/technical/rotating/layout.xml
```

aufzurufen.
Erst wird die Ressource auf dem lokalen Rechner zwischengespeichert und dann von dort aus geladen.

{{< callout >}}
Manchmal muss der Backslash (`\`) selbst mit einem Backslash versehen werden  (`\\`). Das ist meist auf Shell-Ebene nötig, also wenn man Argumente beim Aufruf des speedata Publishers übergibt.
{{< /callout >}}