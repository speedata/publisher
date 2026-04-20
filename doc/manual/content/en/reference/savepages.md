---
linktitle: "SavePages"
weight: 810
type: docs
---

# `SavePages`


This command is used for two different but similar purposes.

1: Everything enclosed in [`SavePages`]({{% relref "savepages" %}}) is saved internally and not placed into the PDF. Useful if the output might be discarded.

2: “Future mode”: Create pages that have been previously reserved by [`InsertPages`]({{% relref "insertpages" %}}).



## Child elements

<a href="../addsearchpath"><code>AddSearchpath</code></a>, <a href="../attachfile"><code>AttachFile</code></a>, <a href="../bookmark"><code>Bookmark</code></a>, <a href="../clearpage"><code>ClearPage</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../definecolor"><code>DefineColor</code></a>, <a href="../definefontalias"><code>DefineFontalias</code></a>, <a href="../definefontfamily"><code>DefineFontfamily</code></a>, <a href="../definematter"><code>DefineMatter</code></a>, <a href="../definetextformat"><code>DefineTextformat</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../group"><code>Group</code></a>, <a href="../hyphenation"><code>Hyphenation</code></a>, <a href="../include"><code>Include</code></a>, <a href="../insertpages"><code>InsertPages</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loaddataset"><code>LoadDataset</code></a>, <a href="../loadfontfile"><code>LoadFontfile</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../nextframe"><code>NextFrame</code></a>, <a href="../nextrow"><code>NextRow</code></a>, <a href="../options"><code>Options</code></a>, <a href="../output"><code>Output</code></a>, <a href="../pdfoptions"><code>PDFOptions</code></a>, <a href="../pageformat"><code>Pageformat</code></a>, <a href="../pagetype"><code>Pagetype</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../processnode"><code>ProcessNode</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../setgrid"><code>SetGrid</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../sortsequence"><code>SortSequence</code></a>, <a href="../structureelement"><code>StructureElement</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../until"><code>Until</code></a>, <a href="../value"><code>Value</code></a>, <a href="../while"><code>While</code></a>

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`name` (text)
: The name of the discarded output (1) or for the reserved pages (2). For later/earlier retrieval with [`InsertPages`]({{% relref "insertpages" %}}).





## Remarks

The second mode has been introduced in version 3.7.12.




## Example


First mode:



```xml
<Record element="data">
  <SavePages name="foo">
    <Loop select="100">
      <PlaceObject>
        <Textblock>
          <Paragraph><Value>Hello world</Value></Paragraph>
        </Textblock>
      </PlaceObject>
    </Loop>
  </SavePages>
  <Message select="sd:count-saved-pages('foo')"/>
  <InsertPages name="foo"/>
</Record>

```

“Future mode”



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
                        <Value>This will be the first page</Value>
                    </Paragraph>
                </Textblock>
            </PlaceObject>
        </SavePages>
    </Record>
</Layout>
```



