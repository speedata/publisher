---
linktitle: "Pagetype"
weight: 690
type: docs
---

# `Pagetype`


Define a master page. A master page is chosen depending on the criterion given with the attribute “test”.



## Child elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../grid"><code>Grid</code></a>, <a href="../margin"><code>Margin</code></a>, <a href="../positioningarea"><code>PositioningArea</code></a>

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../include"><code>Include</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`background-color` (text, optional, _since version 5.1.0_)
: The name of the background color (overrides default). The color '-' removes the default.



`columnordering` (optional, _since version 4.1.18_)
: Reverse the logical column ordering if in rtl mode. Only changes areas that are next to each other.


  - `ltr`: The columns are ordered from first defined to last defined. (default)
  - `rtl`: Reverse the order of columns. The first defined column will be the last column.

`defaultcolor` (text, optional, _since version 2.9.3_)
: The default text color for this page (unless overridden in Paragraph or Textblock). Defaults to 'black'.



`height` (length, optional, _since version 4.1.13_)
: The height of the page. Defaults to the global setting.



`name` (text)
: Name of the master page. It is for informational purpose and as a selection for [`ClearPage`]({{% relref "clearpage" %}}).



`part` (text, optional, _since version 4.3.4_)
: Set the part of the document for this page type (mainmatter is the default).



`test` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}))
: If this xpath expression evaluates to true, this page is taken as a master page.



`width` (length, optional, _since version 4.1.13_)
: The width of the page. Defaults to the global setting.





## Remarks

The contents of the element at [`AtPageCreation`]({{% relref "atpagecreation" %}}) is executed, as soon as something will be placed on the page. The commands inside [`AtPageShipout`]({{% relref "atpageshipout" %}}) are executed when switching to a new page.

When creating a new page, all page types are tried in reversed order. That means that the later defined master pages have a higher priority. This is important if more than one test in a pagetype definition evaluates to true.




## Example


```xml
<Pagetype name="right page" test=" sd:odd( sd:current-page() ) "/>
```

```xml
<Pagetype name="left page" test=" sd:even( sd:current-page() ) "/>
```

```xml
<Pagetype name="main part right" test=" sd:odd( sd:current-page() ) and $chapter='main' "/>
```

```xml
<Pagetype name="right page" test="sd:odd( sd:current-page() )">
  <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
  <PositioningArea name="frame1">
    <PositioningFrame width="12" height="30" column="2" row="2"/>
    <PositioningFrame width="12" height="30" column="16" row="2"/>
  </PositioningArea>
  <AtPageCreation>
    <PlaceObject column="1">
      <!-- header -->
    </PlaceObject>
  </AtPageCreation>
  <AtPageShipout>
    <PlaceObject column="1">
      <!-- footer -->
    </PlaceObject>
  </AtPageShipout>
</Pagetype>
```



