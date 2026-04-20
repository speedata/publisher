---
linktitle: "ClearPage"
weight: 170
type: docs
---

# `ClearPage`
_since version 4.5.14_

Finishes the current page. 



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`force` (optional)
: Force the creation of a new page when multiple consecutive [`ClearPage`]({{% relref "clearpage" %}}) commands occur.



`matter` (optional)
: Set the matter for the new page.



`openon` (optional)
: The next current page will be a left or a right page. E.g. when on page 1 and openon="right" then page 2 is empty and the next current page is 3.


  - `left`: The next objects will be placed on a left page.
  - `right`: The next objects will be placed on a right page.

`pagetype` (text, optional)
: The name of the next page type that should be used. If an InsertPage follows the NextPage, the pagetype is used for the first inserted page.



`skippagetype` (text, optional)
: The pagetype of the blank page if inserted (see the attribute openon).





## Remarks

This used to be the command `<NewPage>`. NewPage is kept internally for backwards compatibility, but had incorrect behaviour.




## Example


```xml
<Record element="data">
  <PlaceObject>
    <Textblock>
      <Paragraph><Value>This is page 1</Value></Paragraph>
    </Textblock>
  </PlaceObject>
  <ClearPage openon="right"/>
  <PlaceObject>
    <Textblock>
      <Paragraph><Value>And this is page 3</Value></Paragraph>
    </Textblock>
  </PlaceObject>
</Record>

```



