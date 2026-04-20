---
linktitle: "ForAll"
weight: 350
type: docs
---

# `ForAll`


Ruft die Kindelemente für alle Daten-Elemente auf, die auf das Muster bei `select` passen.



## Kindelemente

<a href="../a"><code>A</code></a>, <a href="../addsearchpath"><code>AddSearchpath</code></a>, <a href="../attachfile"><code>AttachFile</code></a>, <a href="../attribute"><code>Attribute</code></a>, <a href="../b"><code>B</code></a>, <a href="../barcode"><code>Barcode</code></a>, <a href="../bookmark"><code>Bookmark</code></a>, <a href="../box"><code>Box</code></a>, <a href="../br"><code>Br</code></a>, <a href="../clearpage"><code>ClearPage</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../column"><code>Column</code></a>, <a href="../columns"><code>Columns</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../definecolor"><code>DefineColor</code></a>, <a href="../definefontalias"><code>DefineFontalias</code></a>, <a href="../definefontfamily"><code>DefineFontfamily</code></a>, <a href="../definematter"><code>DefineMatter</code></a>, <a href="../definetextformat"><code>DefineTextformat</code></a>, <a href="../element"><code>Element</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../group"><code>Group</code></a>, <a href="../hspace"><code>HSpace</code></a>, <a href="../html"><code>HTML</code></a>, <a href="../hyphenation"><code>Hyphenation</code></a>, <a href="../i"><code>I</code></a>, <a href="../image"><code>Image</code></a>, <a href="../include"><code>Include</code></a>, <a href="../initial"><code>Initial</code></a>, <a href="../insertpages"><code>InsertPages</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loaddataset"><code>LoadDataset</code></a>, <a href="../loadfontfile"><code>LoadFontfile</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../mark"><code>Mark</code></a>, <a href="../message"><code>Message</code></a>, <a href="../nextframe"><code>NextFrame</code></a>, <a href="../nextrow"><code>NextRow</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../options"><code>Options</code></a>, <a href="../output"><code>Output</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../pageformat"><code>Pageformat</code></a>, <a href="../pagetype"><code>Pagetype</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../positioningarea"><code>PositioningArea</code></a>, <a href="../positioningframe"><code>PositioningFrame</code></a>, <a href="../processnode"><code>ProcessNode</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../setgrid"><code>SetGrid</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../sortsequence"><code>SortSequence</code></a>, <a href="../span"><code>Span</code></a>, <a href="../structureelement"><code>StructureElement</code></a>, <a href="../sub"><code>Sub</code></a>, <a href="../sup"><code>Sup</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tablenewpage"><code>TableNewPage</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../tablerule"><code>Tablerule</code></a>, <a href="../td"><code>Td</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../trace"><code>Trace</code></a>, <a href="../transformation"><code>Transformation</code></a>, <a href="../u"><code>U</code></a>, <a href="../until"><code>Until</code></a>, <a href="../vspace"><code>VSpace</code></a>, <a href="../value"><code>Value</code></a>, <a href="../while"><code>While</code></a>

## Elternelemente

<a href="../a"><code>A</code></a>, <a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../color"><code>Color</code></a>, <a href="../columns"><code>Columns</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../element"><code>Element</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../ol"><code>Ol</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../pagetype"><code>Pagetype</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../span"><code>Span</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tablefoot"><code>Tablefoot</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../td"><code>Td</code></a>, <a href="../text"><code>Text</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../ul"><code>Ul</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`limit` (Zahl, optional, veraltet)
: Die Anzahl der Kinder wird durch die Zahl begrenzt.



`select` ([XPath-Ausdruck]({{% relref "../manual/xpathref/xpath" %}}))
: Wählt die Kindelemente aus.



`start` (Zahl, optional, _seit Version 2.3.67_, veraltet)
: Der erste Eintrag der verarbeitet werden soll. Voreinstellung ist 1.





## Bemerkungen

Mit dem aktuellen XPath parser dürfen start und limit nicht mehr angegeben werden. Dafür müssen XPath Prädikate benutzt werden, das sind Ausdrücke in eckigen Klammern. Z.B. start="4" und limit="8" könnte mit `element[position() > 3 and position() &lt; 8]` erreicht werden. 




## Beispiel


```xml
<Record element="data">
  <PlaceObject>
    <Table>
      <ForAll select="eintrag">
        <Tr><Td><Paragraph><Value select="string(.)"></Value></Paragraph></Td></Tr>
      </ForAll>
    </Table>
  </PlaceObject>
</Record>
```

Erzeugt eine Tabellenzeile für alle Elemente `eintrag` im Datensatz `data`. So müsste in etwa ein entsprechender Eintrag in den Daten aussehen:



```xml
<data>
  <eintrag>a</eintrag>
  <eintrag>b</eintrag>
  <eintrag>c</eintrag>
</data>
```



