---
linktitle: "Overlay"
weight: 660
type: docs
---

# `Overlay`
_since version 2.3.26_

Overlays the first element with the following “positions”.



## Child elements

<a href="../a"><code>A</code></a>, <a href="../barcode"><code>Barcode</code></a>, <a href="../box"><code>Box</code></a>, <a href="../circle"><code>Circle</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../image"><code>Image</code></a>, <a href="../position"><code>Position</code></a>, <a href="../rule"><code>Rule</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../table"><code>Table</code></a>, <a href="../textblock"><code>Textblock</code></a>, <a href="../transformation"><code>Transformation</code></a>

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../td"><code>Td</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes
(none)



## Example


```xml
<PlaceObject>
  <Table>
    <Tr>
      <Td>
        <Overlay>
          <Image width="5" height="4" file="_samplea.pdf"/>
          <Position x="0" y="0">
            <Box width="2" height="2" background-color="white"/>
          </Position>
          <Position x="0" y="0">
            <Barcode select="'speedata'" type="QRCode" width="2" height="2"/>
          </Position>
        </Overlay>
      </Td>
      <Td>
        <Image file="_sampleb.pdf" width="5" height="4" clip="no"/>
      </Td>
    </Tr>
  </Table>
</PlaceObject>
```

which gives the following output



![ref-overlay.png](/img/ref-overlay.png)



