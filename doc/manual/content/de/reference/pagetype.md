---
linktitle: "Pagetype"
weight: 690
type: docs
---

# `Pagetype`


Definiert eine Seitenvorlage. Anhand der Kriterien, die im Attribut test angegeben werden, wählt das System eine Seitenvorlage aus.



## Kindelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../grid"><code>Grid</code></a>, <a href="../margin"><code>Margin</code></a>, <a href="../positioningarea"><code>PositioningArea</code></a>

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`background-color` (Text, optional, _seit Version 5.1.0_)
: Der Name der Hintergrundfarbe (überschreibt Voreinstellung). Die Farbe '-' löscht die Voreinstellung.



`columnordering` (optional, _seit Version 4.1.18_)
: Drehe die Reihenfolge der Spalten im rtl-Modus um. Ändert nur die Bereiche, die nebeneneinander sind.


  - `ltr`: Die Spalten sind in der Reihenfolge von erster zu letzten. (Voreinstellung)
  - `rtl`: Kehre die Reihenfolge der Spalten um. Die zuerst definiert Spalte wird als letzte gefüllt.

`defaultcolor` (Text, optional, _seit Version 2.9.3_)
: Die Textfarbe der Seite, sofern sie nicht in Textblock oder Paragraph überschrieben wird. Voreinstellung ist 'black'.



`height` (Längenangabe, optional, _seit Version 4.1.13_)
: Die Seitenhöhe. Voreinstellung ist die globale Einstellung.



`name` (Text)
: Name der Seitenvorlage. Der Name ist zu Informationszwecken und zur Auswahl bei [`ClearPage`]({{% relref "clearpage" %}}).



`part` (Text, optional, _seit Version 4.3.4_)
: Setze den Abschnitt des Dokuments, in dem der Seitentyp enthalten ist (mainmatter ist die Voreinstellung)



`test` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}))
: Wenn der XPath-Ausdruck »wahr« ergibt, dann wird diese Seite als Vorlage genommen.



`width` (Längenangabe, optional, _seit Version 4.1.13_)
: Die Seitenbreite. Voreinstellung ist die globale Einstellung.





## Bemerkungen

Die Inhalte des Elements [`AtPageCreation`]({{% relref "atpagecreation" %}}) werden ausgeführt, sobald das erste Mal auf die Seite zugegriffen wird, bei [`AtPageShipout`]({{% relref "atpageshipout" %}}) werden die Inhalte ausgeführt, sobald
        beispielsweise [`ClearPage`]({{% relref "clearpage" %}}) aufgerufen wird.

Wenn eine neue Seite erzeugt wird, werden die Seitentypen in umgekehrter Reihenfolge geprüft. Das bedeutet, dass die allgemeineren Seitentypen zuerst definiert werden müssen, später die
        speziellen. Das ist nur dann wichtig, wenn mehrere Bedingungen »wahr« ergeben würden. 




## Beispiel


```xml
<Pagetype name="rechte Seite" test=" sd:odd( sd:current-page() ) ">
```

```xml
<Pagetype name="linke Seite" test=" sd:even( sd:current-page() ) ">
```

```xml
<Pagetype name="Hauptteil rechte Seite" test=" sd:odd( sd:current-page() )  and $kapitel='hauptteil' ">
```

```xml
<Pagetype name="rechte Seite" test="sd:odd( sd:current-page() )">
  <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
  <AtPageCreation>
    <PlaceObject>
      ...
    </PlaceObject>
  </AtPageCreation>
  <AtPageShipout>
    <PlaceObject>
      ....
    </PlaceObject>
  </AtPageShipout>
  <PositioningArea name="rahmen1">
    <PositioningFrame width="12" height="30" column="2" row="2"/>
    <PositioningFrame width="12" height="30" column="16" row="2"/>
  </PositioningArea>
</Pagetype>
```



