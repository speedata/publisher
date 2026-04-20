---
linktitle: "Message"
weight: 580
type: docs
---

# `Message`


Gibt eine Textmeldung auf der Konsole und in der Protokolldatei aus.



## Kindelemente

<a href="../element"><code>Element</code></a>, <a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`error` (optional)
: Zusätzlich einen Fehler melden.


  - `yes`: Fehler ausgeben.
  - `no`: Keinen Fehler ausgeben (Voreinstellung).

`errorcode` (Zahl, optional, _seit Version 2.3.69_)
: Wenn ein Fehler ausgegeben wird, benutze diesen Fehlercode. Voreinstellung 1. Negative Werte sind für interne Zwecke reserviert.



`exit` (optional, _seit Version 3.1.17_)
: Soll sich der Publisher beenden?


  - `no`: Der speedata Publisher erzeugt weiterhin die PDF-Datei
  - `yes`: Der speedata Publisher beendet sich ohne die PDF-Datei fertig zu stellen.

`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}), optional)
: Inhalt der Nachricht. Alternativ dazu: Kindelemente Wert innerhalb des Elements »[`Message`]({{% relref "message" %}})«






## Beispiel


```xml
<Message select="concat('Price: ',@price)" error="no"/>
```

```xml
<Record element="Datensatz">
  <Message>
    <Value>Attribut Preis: </Value>
    <Value select="@Preis"></Value>
  </Nachricht>
</Record>
```



