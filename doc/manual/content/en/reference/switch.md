---
linktitle: "Switch"
weight: 910
type: docs
---

# `Switch`


Create an if-then-else construct. The test attribute of each [`Case`]({{% relref "case" %}}) commands is evaluated until it yields true. The contents of the Case gets executed. If no test succeeds, the (optional) [`Otherwise`]({{% relref "otherwise" %}}) gets executed.



## Child elements

<a href="../case"><code>Case</code></a>, <a href="../otherwise"><code>Otherwise</code></a>

## Parent elements

<a href="../a"><code>A</code></a>, <a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../color"><code>Color</code></a>, <a href="../columns"><code>Columns</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../element"><code>Element</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../function"><code>Function</code></a>, <a href="../i"><code>I</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../position"><code>Position</code></a>, <a href="../positioningarea"><code>PositioningArea</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../span"><code>Span</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tablefoot"><code>Tablefoot</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../td"><code>Td</code></a>, <a href="../text"><code>Text</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes
(none)



## Example


```xml
<Record element="data">
  <SetVariable variable="counter" select="3"/>
  <Switch>
    <Case test=" $counter &lt; 5">
      <SetVariable variable="text" select="'Less than 5'"/>
    </Case>
    <Case test=" $counter &lt; 20">
      <SetVariable variable="text" select="'Less than 20'"/>
    </Case>
    <Otherwise>
      <SetVariable variable="text" select="'Larger or equal to 20'"/>
    </Otherwise>
  </Switch>
  <PlaceObject>
    <Textblock>
      <Paragraph><Value select="$text"/></Paragraph>
    </Textblock>
  </PlaceObject>
</Record>
```



## Info


You have to be careful to encode the test with the rules of XML: that is “less” must be written as `&lt;`, since `<` must not be part of text contents.



A Switch may be part of nearly all commands. It dissolves and only the contents of the Case or Otherwise gets replaced by the whole construct.




