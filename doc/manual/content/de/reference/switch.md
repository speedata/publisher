---
linktitle: "Switch"
weight: 910
type: docs
---

# `Switch`


Erzeugt eine „Wenn-Dann-Abfrage“. Das heißt, für jedes Kindelement [`Case`]({{% relref "case" %}}) wird überprüft, ob die Bedingung erfüllt ist. Wenn ja, dann wird der Inhalt des Kindelements [`Case`]({{% relref "case" %}}) ausgeführt und die Verarbeitung hinter der Fallunterscheidung fortgesetzt. Wenn keine Bedingung erfüllt wurde und ein Element [`Otherwise`]({{% relref "otherwise" %}}) gefunden wurde, wird der         Inhalt des Elements [`Otherwise`]({{% relref "otherwise" %}}) ausgeführt. Durch das frühzeitige Abbrechen werden nachfolgende Fälle nicht weiter untersucht (siehe Beispiel).



## Kindelemente

<a href="../case"><code>Case</code></a>, <a href="../otherwise"><code>Otherwise</code></a>

## Elternelemente

<a href="../a"><code>A</code></a>, <a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../color"><code>Color</code></a>, <a href="../columns"><code>Columns</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../element"><code>Element</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../function"><code>Function</code></a>, <a href="../i"><code>I</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../positioningarea"><code>PositioningArea</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../span"><code>Span</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tablefoot"><code>Tablefoot</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../td"><code>Td</code></a>, <a href="../text"><code>Text</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute
(keine)



## Beispiel


```xml
<Record element="...">
  <SetVariable variable="zähler" select="3"/>
  <Switch>
    <Case test=" $zähler &lt; 5">
      <SetVariable variable="text" select="'Kleiner als 5'" />
    </Case>
    <Case test=" $zähler &lt; 20">
      <SetVariable variable="text" select="'Kleiner als 20'" />
    </Case>
    <Otherwise>
      <SetVariable variable="text" select="'Größer als oder gleich 20'" />
    </Otherwise>
  </Switch>
  <PlaceObject>
    <Textblock>
      <Paragraph><Value select="$text" /></Paragraph>
    </Textblock>
  </PlaceObject>
</Record>
```



## Hinweis


»Größer« und »kleiner« Vergleiche müssen nach den Regeln von XML kodiert werden. Für »größer« kann das `>` Zeichen oder `&gt;` benutzt werden, »kleiner« muss zwingend als `&lt;`
        ausgeschrieben sein, da das Zeichen `<` nicht in einem XML Attribut vorkommen darf.



Eine Fallunterscheidung kann in fast allen Elementen vorkommen. Das Ergebnis der Fallunterscheidung (also vom benutzten Element Case oder Otherwise) wird an das umgebende Element
        zurückgegeben. So wird beispielsweise aus



```xml
<Td>
  <Paragraph>
    <Switch>
      <Case test=" $zeile > 10 ">
       <Value>Zeile ist größer als 10</Value>
      </Case>
      <Otherwise>
        <Value>Zeile ist kleiner oder gleich 10</Value>
      </Otherwise>
    </Switch>
  </Paragraph>
</Td>
```

```xml
<Td>
  <Paragraph>
    <Value>Zeile ist größer als 10</Value>
  </Paragraph>
</Td>

```

oder



```xml
<Td>
  <Paragraph>
    <Value>Zeile ist kleiner oder gleich 10</Value>
  </Paragraph>
</Td>
```

je nach Inhalt der Variablen.




