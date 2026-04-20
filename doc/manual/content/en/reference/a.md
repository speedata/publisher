---
linktitle: "A"
weight: 20
type: docs
---

# `A`


Insert hyperlink to a URL.



## Child elements

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../barcode"><code>Barcode</code></a>, <a href="../br"><code>Br</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../hspace"><code>HSpace</code></a>, <a href="../i"><code>I</code></a>, <a href="../image"><code>Image</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../span"><code>Span</code></a>, <a href="../sub"><code>Sub</code></a>, <a href="../sup"><code>Sup</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../span"><code>Span</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`bordercolor` (text, optional, _since version 4.15.7_)
: Set the color of the border (Adobe Acrobat ony).



`description` (text, optional, _since version 4.19.12_)
: An alternative text for accessibility



`embedded` (text, optional, _since version 4.15.11_)
: Link to an attached file. To open a page other than the first page, set the page attribute, to open a named destination, set the link attribute.



`href` (text, optional)
: The target of the hyperlink (URI). Example: `https://www.speedata.de`



`link` (text, optional, _since version 3.3.8_)
: The target of the document link (a Mark). Example: `article123`. When linking to embedded files, the link attribute may contain the named destination of the target.



`page` (number, optional, _since version 4.3.5_)
: Link to a (logical) page number. When linking to embedded files, the page attribute may contain the page number of the target.






## Example


Create a simple hyperlink to a URL.



```xml
<PlaceObject>
  <Textblock>
    <Paragraph><Value>See the </Value>
      <A href="https://www.speedata.de">
        <Value>homepage</Value>
      </A>
      <Value> for more information.</Value>
    </Paragraph>
  </Textblock>
</PlaceObject>
```

Create a hyperlink to an attached document. Only supported on a few PDF viewers.



```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
        xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <AttachFile type="application/pdf"
              filename="document.pdf"
              description="An important document" />
  <Record element="data">
    <PlaceObject>
      <Textblock>
        <Paragraph>
          <A embedded="document.pdf" page="5">
            <Value>See the page 5 of the document.</Value>
          </A>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```



