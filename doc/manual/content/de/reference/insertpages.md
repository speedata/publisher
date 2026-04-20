---
linktitle: "InsertPages"
weight: 480
type: docs
---

# `InsertPages`


Fügt zuvor gespeicherte Seiten ein oder reserviert Raum für zukünftig erzeugte Seiten.

Es gibt zwei Modi für diesen Befehl. Der erste Modus ist, dass zuvor mit [`SavePages`]({{% relref "savepages" %}}) erzeugte Seiten eingefügt werden. Der zweite Modus (»zukünftige Seiten«) reserviert Seiten im PDF, die später mit [`SavePages`]({{% relref "savepages" %}}) erzeugt werden.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`name` (Text)
: Der Name der gespeicherten Seiten.



`pages` (Zahl, optional, _seit Version 3.7.12_)
: Anzahl der Seiten die freigehalten werden sollen. Funktioniert im »Modus zukünftige Seiten«.





## Bemerkungen

Hilfreich um Seiten erst einmal virtuell zu erzeugen und dann einzufügen, z.B. um eine Höchstzahl an Seiten zu garantieren.

Ebenfalls hilfreich, um ein Inhaltsverzeichnis am Ende des Durchlaufs zu erzeugen das aber am Anfang des Dokuments erscheinen soll.




## Beispiel


```xml
<Record element="data">
  <SavePages name="foo">
    <Loop select="100">
      <PlaceObject>
        <Textblock>
          <Paragraph><Value>Hallo Welt</Value></Paragraph>
        </Textblock>
      </PlaceObject>
    </Loop>
  </SavePages>
  <Message select="sd:count-saved-pages('foo')"/>
  <InsertPages name="foo"/>
</Record>

```



