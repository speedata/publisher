---
linktitle: "Output"
weight: 650
type: docs
---

# `Output`


This command is similar to [`PlaceObject`]({{% relref "placeobject" %}}) and is currently limited to output text which can be broken across positioning frames and which can wrap around objects.



## Child elements

<a href="../html"><code>HTML</code></a>, <a href="../text"><code>Text</code></a>

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`allocate` (optional)
: Should text flow around already allocated objects? This currently works on the current page only.


  - `yes`: Regular behavior: the text does not flow around objects.
  - `auto`: Text flows around allocated objects.

`area` (text, optional)
: The name of the positioning frame for the text.



`balance` (optional, _since version 3.2.1_)
: Balance text on the last page (experimental)


  - `yes`: Balance the last page
  - `no`: Do not balance the last page (default)

`last-padding-bottom-max` (length, optional, _since version 3.2.1_)
: The maximum padding on the last page when valign-last is set to bottom



`row` (number, optional)
: The starting row for the text.



`valign-last` (optional, _since version 3.2.1_)
: When balancing: align the last columns at the top (default) or bottom (experimental).


  - `top`: Top alignment (default)
  - `bottom`: Align at the bottom

`width` (number or length, optional, _since version 5.1.19_)
: Width of the text






## Example


```xml
<Pagetype name="page" test="true()">
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
          <Value>A wonderful serenity has taken possession of my entire soul,...</Value>
        </Paragraph>
      </Text>
    </Output>
  </Record>
```



