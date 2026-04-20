---
linktitle: "Function"
weight: 370
type: docs
---

# `Function`


Define a function



## Child elements

<a href="../clearpage"><code>ClearPage</code></a>, <a href="../column"><code>Column</code></a>, <a href="../columns"><code>Columns</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../group"><code>Group</code></a>, <a href="../loaddataset"><code>LoadDataset</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../nextframe"><code>NextFrame</code></a>, <a href="../nextrow"><code>NextRow</code></a>, <a href="../output"><code>Output</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../param"><code>Param</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../processnode"><code>ProcessNode</code></a>, <a href="../savedataset"><code>SaveDataset</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../tablefoot"><code>Tablefoot</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../tablerule"><code>Tablerule</code></a>, <a href="../td"><code>Td</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../layout"><code>Layout</code></a>, <a href="../section"><code>Section</code></a>

## Attributes


`name` (text)
: The name of the function (with namespace prefix).






## Example


```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
        xmlns:sd="urn:speedata:2009/publisher/functions/en"
        xmlns:fn="mynamespace">

        <Record element="data">
            <PlaceObject>
                <Textblock>
                    <Paragraph>
                        <Value select="fn:add(3,4)" />
                    </Paragraph>
                </Textblock>
            </PlaceObject>
        </Record>

        <Function name="fn:add">
            <Param name="a" />
            <Param name="b" />
            <Value select="$a + $b" />
        </Function>
    </Layout>
```

Print out the number 7.





