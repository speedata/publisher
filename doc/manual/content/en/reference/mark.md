---
linktitle: "Mark"
weight: 570
type: docs
---

# `Mark`


Sets an invisible mark into the output. This is helpful when you want to know on which page the mark is placed on.



## Child elements

(none)

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../td"><code>Td</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`append` (optional)
: When yes, append the current page to the previous values of the mark. Useful to get page ranges in an index. (Default is no.)


  - `yes`: Append the page number to the previous value of the mark.
  - `no`: Replace the previous value.

`pdftarget` (yes or no, optional, _since version 3.3.8_)
: Set a pdf target that can be referenced by [`A`]({{% relref "a" %}})



`select` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}))
: The name of the mark to be set.



`shiftup` (length, optional, _since version 4.13.2_)
: Raise the position of the hyperlink anchor by this amount.






## Example


```xml
<Pageformat width="210mm" height="4cm"/>

<Record element="data">
  <PlaceObject>
    <Textblock>
      <Paragraph>
        <Value>
          Row
          Row
          Row
          Row
        </Value>
      </Paragraph>
    </Textblock>
    <Textblock>
      <Mark select="'textstart'"/>
      <Paragraph>
        <Value>
          Row
          Row
          Row
        </Value>
      </Paragraph>
    </Textblock>
  </PlaceObject>
  <ClearPage/>
  <Message select="sd:pagenumber('textstart')"></Message>
</Record>

```



## Info


Marks get saved for subsequent runs.




