---
linktitle: "ClearPage"
weight: 170
type: docs
---

# `ClearPage`
_seit Version 4.5.14_

Beendet die Ausgabe auf der aktuellen Seite.



## Kindelemente

(keine)

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`force` (optional)
: Seitenausgabe erzwingen, wenn mehrere [`ClearPage`]({{% relref "clearpage" %}}) Befehle hintereinander stehen.



`matter` (optional)
: Legt den Abschnitt (matter) für die neue Seite fest.



`openon` (optional)
: Die nächste aktuelle Seite ist eine linke oder rechte Seite. Z.B. wenn auf Seite 1 ein Seitenwechsel erzwungen wird mit openon="right", dann wird Seite zwei leer und die nächste aktuelle Seite ist die Seite 3.


  - `left`: Die nächsten Objekte werden auf einer linken Seite ausgegeben.
  - `right`: Die nächsten Objekte werden auf einer rechten Seite ausgegeben.

`pagetype` (Text, optional)
: Der Name des Seitentyps der für die nächste Seite genommen werden soll. Falls danach ein InsertPage folgt, wird der Seitentyp für die erste Seite von InsertPage genommen.



`skippagetype` (Text, optional)
: Der Seitentyp der leeren Seite, falls sie eingefügt wird.





## Bemerkungen

Ursprünglich war das der Befehl `<NewPage>`. NewPage wird intern vorerst weiter für Rückwärtskompatibilität beibehalten, hatte aber ein fehlerhaftes Verhalten.




## Beispiel


```xml
<Record element="data">
  <PlaceObject>
    <Textblock>
      <Paragraph>
        <Value>Das ist Seite 1</Value>
      </Paragraph>
    </Textblock>
  </PlaceObject>
  <ClearPage openon="right"/>
  <PlaceObject>
    <Textblock>
      <Paragraph>
        <Value>Das ist Seite 3</Value>
      </Paragraph>
    </Textblock>
  </PlaceObject>
</Record>

```



