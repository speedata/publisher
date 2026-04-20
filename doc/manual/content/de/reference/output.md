---
linktitle: "Output"
weight: 650
type: docs
---

# `Output`


Dieser Befehl ist ähnlich zu [`PlaceObject`]({{% relref "placeobject" %}}) und dient derzeit nur dazu, Text auszugeben, der auf mehrere Seite umbrochen werden kann und sich dem freien Platz auf der Seite anpassen kann.



## Kindelemente

<a href="../html"><code>HTML</code></a>, <a href="../text"><code>Text</code></a>

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`allocate` (optional)
: Soll Text um schon vorhandene (belegte) Bereiche fließen? Die Rasterhöhe muss gleich dem Zeilenabstand der Textschriftart sein. Außerdem funktioniert dies nur auf der aktuellen Seite.


  - `yes`: Normales Verhalten, der Text hat eine rechteckige Form.
  - `auto`: Text fließt um belegte Bereiche.

`area` (Text, optional)
: Der Name des Platzierungsbereichs für den Text.



`balance` (optional, _seit Version 3.2.1_)
: Text auf der letzten Seite ausbalancieren (experimentell)


  - `yes`: Letzte Seite ausbalancieren
  - `no`: Letzte Seite nicht ausbalancieren (Voreinstellung)

`last-padding-bottom-max` (Längenangabe, optional, _seit Version 3.2.1_)
: Der maximale Innenabstand auf der letzten Seite, wenn valign-last auf 'bottom' gesetzt ist.



`row` (Zahl, optional)
: Die Startzeile für den Text



`valign-last` (optional, _seit Version 3.2.1_)
: Wenn Spaltenausgleich eingeschaltet ist: Ausrichtung der letzten Seite oben oder unten (experimentell).


  - `top`: Oben ausrichten (Voreinstellung)
  - `bottom`: Unten ausrichten

`width` (Zahl oder Längenangabe, optional, _seit Version 5.1.19_)
: Breite des Textes






## Beispiel


```xml
  <Pagetype name="seite" test="true()">
    <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
    <PositioningArea name="text">
      <PositioningFrame width="9" height="4" row="1" column="1"/>
      <PositioningFrame width="9" height="4" row="1" column="11"/>
      <PositioningFrame width="9" height="4" row="6" column="1"/>
      <PositioningFrame width="9" height="4" row="6" column="11"/>
    </PositioningArea>
  </Pagetype>
  <Record element="data">
    <Output area="text">
      <Text>
        <Paragraph fontfamily="text">
          <Value>Kaum standen am folgenden...</Value>
        </Paragraph>
      </Text>
    </Output>
  </Record>

```



