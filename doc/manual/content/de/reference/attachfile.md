---
linktitle: "AttachFile"
weight: 60
type: docs
---

# `AttachFile`
_seit Version 3.1.1_

Hänge eine Datei an das PDF an. Kann benutzt werden, um eine ZUGFeRD Datei einzubinden.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`description` (Text, optional)
: Textuelle Beschreibung der einzubindenden Datei (für den PDF-Viewer).



`filename` (Text, optional)
: Der Name der Datei, die in die PDF-Datei eingebettet werden soll.



`name` (Text, optional, _seit Version 3.7.3_)
: Name der eingebunden Datei im PDF. Voreinstellung ist `factur-x.xml` falls der Typ `ZUGFeRD invoice` ist.



`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}), optional, _seit Version 3.7.2_)
: Der Inhalt des Datei. Alternativ zum Lesen von der Festplatte.



`type` (Text)
: Der Typ der eingebundenen Datei. Muss ein Media Type (mime type) sein oder `ZUGFeRD invoice`.






## Beispiel


```xml
<AttachFile filename="invoice.xml" description="ZUGFeRD Rechnung" type="ZUGFeRD invoice"/>
```

```xml
<AttachFile select="CrossIndustryDocument" description="ZUGFeRD Rechnung" type="ZUGFeRD invoice"/>
```



## Hinweis


Voraussetzung für das Anhängen einer ZUGFeRD Datei ist das Pro-Paket.




