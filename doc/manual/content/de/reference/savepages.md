---
linktitle: "SavePages"
weight: 810
type: docs
---

# `SavePages`


Dieser Befehl ist für zwei unterschiedliche Szenarien gedacht:

1: Alle Ausgaben innerhalb von [`SavePages`]({{% relref "savepages" %}}) werden intern gespeichert und nicht ins PDF ausgegeben. Sie können später mit [`InsertPages`]({{% relref "insertpages" %}}) eingefügt werden. Hilfreich wenn die Ausgabe ggf. verworfen werden soll.

2: Im Modus »Zukünftige Seiten« wurde schon Platz für diese Seiten mit [`InsertPages`]({{% relref "insertpages" %}}) reserviert.



## Kindelemente

<a href="../addsearchpath"><code>AddSearchpath</code></a>, <a href="../attachfile"><code>AttachFile</code></a>, <a href="../bookmark"><code>Bookmark</code></a>, <a href="../clearpage"><code>ClearPage</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../definecolor"><code>DefineColor</code></a>, <a href="../definefontalias"><code>DefineFontalias</code></a>, <a href="../definefontfamily"><code>DefineFontfamily</code></a>, <a href="../definematter"><code>DefineMatter</code></a>, <a href="../definetextformat"><code>DefineTextformat</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../group"><code>Group</code></a>, <a href="../hyphenation"><code>Hyphenation</code></a>, <a href="../include"><code>Include</code></a>, <a href="../insertpages"><code>InsertPages</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loaddataset"><code>LoadDataset</code></a>, <a href="../loadfontfile"><code>LoadFontfile</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../nextframe"><code>NextFrame</code></a>, <a href="../nextrow"><code>NextRow</code></a>, <a href="../options"><code>Options</code></a>, <a href="../output"><code>Output</code></a>, <a href="../pdfoptions"><code>PDFOptions</code></a>, <a href="../pageformat"><code>Pageformat</code></a>, <a href="../pagetype"><code>Pagetype</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../processnode"><code>ProcessNode</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../setgrid"><code>SetGrid</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../sortsequence"><code>SortSequence</code></a>, <a href="../structureelement"><code>StructureElement</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../until"><code>Until</code></a>, <a href="../value"><code>Value</code></a>, <a href="../while"><code>While</code></a>

## Elternelemente

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`name` (Text)
: Der Name der Ausgabe, die verworfen (1) oder eingefügt (2) wird. Kann später oder früher mit [`InsertPages`]({{% relref "insertpages" %}}) eingefügt werden.





## Bemerkungen

Der zweite Modus besteht seit Version 3.7.12.




## Beispiel


Erste Variante



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

Zweite Variante (»Zukünftige Seiten«)



```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en">
    <Pageformat height="5cm" width="5cm"/>

    <Record element="data">
        <InsertPages name="firstpage" pages="1"/>
        <Loop select="4" variable="n">
            <PlaceObject>
                <Textblock>
                    <Paragraph>
                        <Value select="$n" />
                    </Paragraph>
                </Textblock>
            </PlaceObject>
            <ClearPage />
        </Loop>
        <SavePages name="firstpage">
            <PlaceObject>
                <Textblock>
                    <Paragraph>
                        <Value>Das wird die erste Seite sein.</Value>
                    </Paragraph>
                </Textblock>
            </PlaceObject>
        </SavePages>
    </Record>
</Layout>
```



