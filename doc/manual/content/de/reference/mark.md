---
linktitle: "Mark"
weight: 570
type: docs
---

# `Mark`


Setzt eine unsichtbare Markierung in die Ausgabe. Das ist hilfreich, um die Seitenzahl zu bestimmen, auf der die Marke gelandet ist.



## Kindelemente

(keine)

## Elternelemente

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../td"><code>Td</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`append` (optional)
: Wenn 'yes', dann wird die aktuelle Seitenzahl an den letzten Wert angehängt (mit Komma separiert). Nützlich, um Seitenzahlen wie S. 3-5 im Index zu erstellen. Voreinstellung ist nein.


  - `yes`: Die Seitenzahl an die vorherigen Werte anhängen.
  - `no`: Den vorherigen Wert ersetzen.

`pdftarget` (yes oder no, optional, _seit Version 3.3.8_)
: Setze ein PDF-Ziel, das mit [`A`]({{% relref "a" %}}) referenziert werden kann.



`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}))
: Der Name des Markers, der gesetzt wird.



`shiftup` (Längenangabe, optional, _seit Version 4.13.2_)
: Verschiebe die Position des Hyperlink-Ankers um diesen Betrag.






## Beispiel


```xml
<Pageformat width="210mm" height="4cm"/>

<Record element="data">
  <PlaceObject>
    <Textblock>
      <Paragraph>
        <Value>
        Zeile
        Zeile
        Zeile
        Zeile
        </Value>
      </Paragraph>
    </Textblock>
    <Textblock>
      <Mark select="'Textanfang'"/>
      <Paragraph>
        <Value>
          Zeile
          Zeile
          Zeile
        </Value>
      </Paragraph>
    </Textblock>
  </PlaceObject>
  <ClearPage/>
  <Message select="sd:pagenumber('Textanfang')"/>
</Record>

```



## Hinweis


Marker werden für nachfolgende Läufe gespeichert.




