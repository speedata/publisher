---
linktitle: "Text"
weight: 980
type: docs
---

# `Text`


Create a text that can be broken across text containers or pages. To be used with [`Output`]({{% relref "output" %}})



## Child elements

<a href="../bookmark"><code>Bookmark</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../image"><code>Image</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../ol"><code>Ol</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../ul"><code>Ul</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../output"><code>Output</code></a>

## Attributes


`color` (text, optional)
: The name of the color of the text.



`fontfamily` (text, optional)
: The name of the font family. Defaults to `text`.



`textformat` (text, optional)
: The name of the text format to be applied to the text. Defaults to `text`.






## Example


```xml
<Pagetype name="page" test="true()">
  <Margin left="1cm" right="1cm" top="1cm" bottom="1cm" />
  <PositioningArea name="text">
    <PositioningFrame width="4" height="10" row="1" column="1" />
    <PositioningFrame width="4" height="10" row="1" column="6" />
  </PositioningArea>
</Pagetype>
<Record element="data">
  <Output area="text">
    <Text>
      <Paragraph>
        <Value select="string(.)" />
      </Paragraph>
    </Text>
  </Output>
</Record>

```



