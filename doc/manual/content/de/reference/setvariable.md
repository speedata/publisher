---
linktitle: "SetVariable"
weight: 840
type: docs
---

# `SetVariable`


Weist einer Variablen einen Wert zu. Der Wert kann aus mehreren Elementen bestehen (siehe zweites Beispiel).



## Kindelemente

<a href="../attribute"><code>Attribute</code></a>, <a href="../clearpage"><code>ClearPage</code></a>, <a href="../column"><code>Column</code></a>, <a href="../columns"><code>Columns</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../element"><code>Element</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../ol"><code>Ol</code></a>, <a href="../output"><code>Output</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../sortsequence"><code>SortSequence</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tablenewpage"><code>TableNewPage</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../tablerule"><code>Tablerule</code></a>, <a href="../td"><code>Td</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../ul"><code>Ul</code></a>, <a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../table"><code>Table</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`execute` (optional, _seit Version 4.11.8_)
: Führe den Inhalt sofort aus oder später bei der Benutzung.


  - `now`: Führe den Inhalt sofort aus (Voreinstellung).
  - `later`: Führe den Inhalt bei der Benutzung von [`Copy-of`]({{% relref "copy-of" %}}) aus. Experimentell.

`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}), optional)
: Inhalt, der der Variablen zugewiesen wird.



`trace` (optional)
: Zeige Informationen über die Zuweisung in der Logdatei.


  - `yes`: Zeige Informationen.
  - `no`: Zeige keine Informationen (Voreinstellung).

`type` (optional, _seit Version 4.3.10_)
: Setzt den Datentyp der Variable. Derzeit nur für MetaPost-Variablen unterstützt.


  - `sd:any`: Der voreingestellte Datentyp für die speedata Layoutsprache.
  - `mp:boolean`: Ein boolescher Wert für MetaPost.
  - `mp:cmykcolor`: Eine MetaPost CMYK Farbe.
  - `mp:numeric`: Ein nummerischer Wert für MetaPost.
  - `mp:string`: Eine Zeichenkette für MetaPost.
  - `mp:rgbcolor`: Eine MetaPost RGB Farbe.

`variable` (Text)
: Name der Variablen, der etwas zugewiesen werden soll.





## Bemerkungen

Variablen haben eine globale Sichtbarkeit.




## Beispiel


```xml
<Record element="produkt">
  <SetVariable variable="Textbreite" select="5"/>
  <PlaceObject>
    <Textblock width="{ $Textbreite }">
      <Paragraph>
        <Value select="$Artikelnummer"/>
      </Paragraph>
    </Textblock>
  </PlaceObject>
</Record>
```

Folgendes Beispiel zeigt, wie mehrere Absätze in einer Variablen gespeichert werden, um sie anschließend in einem Textblock auszugeben.



```xml
<Record element="produkte">
  <SetVariable variable="Artikeltext"/>
  <ProcessNode select="artikel"/>
  <PlaceObject>
    <Textblock>
      <Value select=" $Artikeltext "/>
    </Textblock>
  </PlaceObject>
</Record>

<Record element="artikel">
  <SetVariable variable="Artikeltext">
    <!-- Der vorherige Inhalt wird hinzugefügt -->
    <Value select="$Artikeltext"/>
    <Paragraph>
      <Value select=" @beschreibung " />
    </Paragraph>
  </SetVariable>
</Record>
```



