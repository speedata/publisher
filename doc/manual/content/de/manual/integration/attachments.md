---
weight: 78
type: docs
---


Das PDF Dateiformat bietet die Möglichkeit, Dateien in das Dokument einzubetten, so dass diese dann als eigenständige Dokumente heruntergeladen werden können.
Elektronische Rechnungen können z.B. als »menschenlesbares« PDF mit einer angehängten computerlesbaren Beschreibung (als XML) verschickt werden.

Es können beliebig viele Dateien angehängt werden, jedoch nur eine ZUGFeRD-Rechnung.

## Anhängen von Dateien

```xml
<AttachFile description="A nice view"
            type="application/pdf"
            filename="ocean.pdf" />
```

Mit diesem Befehl hängt man eine Datei an das PDF an. Der Typ ist der [Mime-Typ](https://de.wikipedia.org/wiki/Internet_Media_Type) der angehängten Datei.

![So zeigt der Adobe Acrobat die angehängten Dateien an](/img/attachfile.png)

## ZUGFeRD /Factur-X Rechnungen anhängen {{< profeature "Verfügbar im PRO-Paket" >}}

Um eine elektronische Rechnung anzuhängen, muss der Wert bei `type` genau die Zeichenkette `ZUGFeRD invoice` sein:

```xml
<AttachFile description="Electronic invoice"
            type="ZUGFeRD invoice"
            filename="invoice.xml" />
```

Der Ausgabedateiname wird automatisch auf `factur-x.xml` gesetzt für ZUGFeRD Version 2 und `ZUGFeRD-invoice.xml` für Version 1. Dieser Name kann mit `name="..."` überschrieben werden.

Die PDF-Ausgabe muss noch auf PDF/A-3 gestellt werden:

```xml
<PDFOptions format="PDF/A-3" />
```

Das passiert automatisch, sofern der Befehl [`<AttachFile>`]({{< relref "/reference/attachfile" >}}) am Anfang des Dokuments (vor der ersten Seitenausgabe) ausgeführt wird.

{{< callout >}}
Damit ein PDF-Dokument mit PDF/A-3 konform ist, müssen die Farben passend zu den Farbprofilen benutzt werden. In der PDF/A-3 Voreinstellung wird ein OutputIntent für ein CMYK-Farbprofil definiert. Entsprechend müssen die Farben im Dokument in diesem Farbraum definiert werden. Oder es muss ein anderes Farbprofil eingebettet werden.
{{< /callout >}}

![Der Dateiname wird automatisch auf factur-x.xml gesetzt.](/img/attachfile-zugferd.png)

