---
linktitle: "InsertPages"
weight: 480
type: docs
---

# `InsertPages`


Insert previously saved pages or reserve space for pages to be generted in the future.

There are two modes: the first mode is to first save some pages with [`SavePages`]({{% relref "savepages" %}}) and then insert the pages here. The second mode reserves some pages in the PDF (has to be known in advace) that are created in the future (“future mode”) with [`SavePages`]({{% relref "savepages" %}}).



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`name` (text)
: The name of the saved pages.



`pages` (number, optional, _since version 3.7.12_)
: Number of pages to be inserted in “future mode”.





## Remarks

Useful if you require a certain amount of pages and you need to try out how many pages you get by typesetting onto virtual pages.

Also useful to create a table of contents after you have collected all the information and make it appear at the beginning of the document.




## Example


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
  <Message select="sd:count-saved-pages('foo')"></Message>
  <InsertPages name="foo"/>
</Record>

```



