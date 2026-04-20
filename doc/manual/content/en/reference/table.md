---
linktitle: "Table"
weight: 920
type: docs
---

# `Table`


Create a table that is similar to the HTML table model.



## Child elements

<a href="../columns"><code>Columns</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../message"><code>Message</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../tablenewpage"><code>TableNewPage</code></a>, <a href="../tablefoot"><code>Tablefoot</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../tablerule"><code>Tablerule</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../td"><code>Td</code></a>, <a href="../transformation"><code>Transformation</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`balance` (optional, _since version 3.1.24_)
: Tries to balance the table on the last page according to the number of frames. Experimental! 


  - `yes`: Tries to balance.
  - `no`: First column will filled first, default

`border-collapse` (optional)
: Determine if adjacent table cells share borders. The behavior of border-collapse="collapse" is undefined when the table has columndistance or rowdistance set to a non-zero value and if the adjacent borders don't have the same width and color.


  - `separate`: The borders are part of the cell and not shared with its neighbors.
  - `collapse`: The borders of neighboring cells overlap.

`columndistance` (length, optional)
: Distance between two table columns.



`eval` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}), optional)
: Evaluates the given XPath expression and discards its output.



`fontfamily` (text, optional)
: Name of the font family for the table. If not given, the font face ‘text’ is used.



`leading` (length, optional)
: The distance between two rows.



`padding` (length, optional)
: The distance between the table border and the table contents.



`parent` (text, optional, _since version 4.19.23_)
: The id of the parent structure element for tagged PDF



`role` (optional, _since version 4.19.23_)
: The role for PDF/UA (accessibility, tagged PDF)



`stretch` (optional)
: If the table contents is narrow and stretch has the value no, the table only uses the minimal width. If the table contents is wider than the value width or stretch has the value max, the table's width is the size given in the width attribute.


  - `max`: Stretch the table to its given width.
  - `no`: The table width is the minimum width depending on it's contents.

`textformat` (text, optional, _since version 3.7.23_)
: The text format for the table. Defaults to `__leftaligned` if no align attribute is given.



`vexcess` (optional, _since version 4.5.12_)
: Set behaviour when cells stretch in vertical direction due to rowspans.


  - `stretch`: Stretch all table cells evenly (default).
  - `bottom`: Only stretch the last table cell.

`width` (number or length, optional)
: The maximum width of the table (in grid cells or absolute values). Defaults to the available space.





## Remarks

The table cells may contain Paragraphs, Images and other objects that are allowed in [`PlaceObject`]({{% relref "placeobject" %}}).




## Example


```xml

<Record element="data">
  <PlaceObject>
    <Table stretch="max" padding="1pt">
      <Tablehead>
        <Tr background-color="gray">
          <Td colspan="3"/>
          <Td border-left="0.2pt" border-left-color="white" colspan="6" align="center">
            <Paragraph><B><Value>Total</Value></B></Paragraph></Td>
          <Td border-left="0.2pt" border-left-color="white"/>
        </Tr>
        <Tr background-color="gray">
          <Td/>
          <Td><Paragraph><B><Value>Clubs</Value></B></Paragraph></Td>
          <Td><Paragraph><B><Value>P</Value></B></Paragraph></Td>
          <Td align="center" border-left="0.2pt" border-left-color="white">
            <Paragraph><B><Value>W</Value></B></Paragraph>
          </Td>
          <Td align="center"><Paragraph><B><Value>D</Value></B></Paragraph></Td>
          <Td align="center"><Paragraph><B><Value>L</Value></B></Paragraph></Td>
          <Td align="center"><Paragraph><B><Value>F</Value></B></Paragraph></Td>
          <Td align="center"><Paragraph><B><Value>A</Value></B></Paragraph></Td>
          <Td align="center"><Paragraph><B><Value>+/-</Value></B></Paragraph></Td>
          <Td align="center" border-left="0.2pt" border-left-color="white">
            <Paragraph><B><Value>Pts</Value></B></Paragraph>
          </Td>
        </Tr>
      </Tablehead>
      <ForAll select="entry">
        <Tr>
          <Td align="left"><Paragraph><Value select="@pos"/></Paragraph></Td>
          <Td align="left"><Paragraph><Value select="@name"/></Paragraph></Td>
          <Td align="center"><Paragraph><Value select="@p"/></Paragraph></Td>
          <Td align="center" border-left="0.2pt" border-left-color="gray">
            <Paragraph><Value select="@tw"/></Paragraph>
          </Td>
          <Td align="center"><Paragraph><Value select="@td"/></Paragraph></Td>
          <Td align="center"><Paragraph><Value select="@tl"/></Paragraph></Td>
          <Td align="center"><Paragraph><Value select="@ta"/></Paragraph></Td>
          <Td align="center"><Paragraph><Value select="@tf"/></Paragraph></Td>
          <Td align="center"><Paragraph><Value select="@tpm"/></Paragraph></Td>
          <Td align="center" border-left="0.2pt" border-left-color="gray">
            <Paragraph><Value select="@pts"/></Paragraph>
          </Td>
        </Tr>
      </ForAll>
    </Table>
  </PlaceObject>
</Record>

```

Using the following data:



```xml
<data>
  <entry pos="1" name="Paris Saint-Germain FC" p="6"
      tw="5" td="0" tl="1" tf="14" ta="3" tpm="11" pts="15" />
  <entry pos="2" name="FC Porto" p="6"
      tw="4" td="1" tl="1" tf="10" ta="4" tpm="6" pts="13" />
  <entry pos="3" name="FC Dynamo Kyiv" p="6"
      tw="1" td="2" tl="3" tf="6"  ta="10" tpm="-4" pts="5" />
  <entry pos="4" name="GNK Dinamo Zagreb" p="6"
      tw="0" td="1" tl="5" tf="1"  ta="14" tpm="-13" pts="1" />
</data>
```

![ref-table-en.png](/img/ref-table-en.png)



