---
linktitle: "SetVariable"
weight: 840
type: docs
---

# `SetVariable`


Associates a value with a variable name. The value can be a simple value or a more complex one consisting of several elements.



## Child elements

<a href="../attribute"><code>Attribute</code></a>, <a href="../clearpage"><code>ClearPage</code></a>, <a href="../column"><code>Column</code></a>, <a href="../columns"><code>Columns</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../element"><code>Element</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../ol"><code>Ol</code></a>, <a href="../output"><code>Output</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../sortsequence"><code>SortSequence</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tablenewpage"><code>TableNewPage</code></a>, <a href="../tablehead"><code>Tablehead</code></a>, <a href="../tablerule"><code>Tablerule</code></a>, <a href="../td"><code>Td</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../ul"><code>Ul</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../table"><code>Table</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`execute` (optional, _since version 4.11.8_)
: Execute the contents of setvariable now or execute it on usage.


  - `now`: Execute the contents during SetVariable (default).
  - `later`: Execute the contents when evaluated during [`Copy-of`]({{% relref "copy-of" %}}). Experimental.

`select` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}), optional)
: The value of the contents.



`trace` (optional)
: Show information about the assignment in the log file.


  - `yes`: Show information.
  - `no`: Don't show information (default).

`type` (optional, _since version 4.3.10_)
: Set the data type of the variable. Currently only supported for MetaPost variables.


  - `sd:any`: The default (any) datatype for variables in the speedata layout language.
  - `mp:boolean`: A MetaPost boolean value.
  - `mp:cmykcolor`: A MetaPost CMYK color.
  - `mp:numeric`: A MetaPost numeric value.
  - `mp:string`: A MetaPost string value.
  - `mp:rgbcolor`: A MetaPost RGB color.

`variable` (text)
: The name of the variable that holds the contents.





## Remarks

Variables have global scope.




## Example


```xml
<Record element="product">
  <SetVariable variable="wd" select="5"/>
  <PlaceObject>
    <Textblock width="{ $wd }">
      <Paragraph>
        <Value select="$articlenumber"/>
      </Paragraph>
    </Textblock>
  </PlaceObject>
</Record>

```

The following example shows a more complex scenario: you can collect complex elements in a variable.



```xml
<Record element="products">
  <SetVariable variable="articletext"/>
  <ProcessNode select="article"/>
  <PlaceObject>
    <Textblock>
      <Value select=" $articletext "/>
    </Textblock>
  </PlaceObject>
</Record>

<Record element="article">
  <SetVariable variable="articletext">
    <!-- the previous contents is added -->
    <Value select="$articletext"/>
    <Paragraph>
      <Value select=" @description "/>
    </Paragraph>
  </SetVariable>
</Record>

```



