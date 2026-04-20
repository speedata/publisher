---
linktitle: "A"
weight: 20
type: docs
---

# `A`


Hyperlink auf eine URL einfügen.



## Kindelemente

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../barcode"><code>Barcode</code></a>, <a href="../br"><code>Br</code></a>, <a href="../clip"><code>Clip</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../frame"><code>Frame</code></a>, <a href="../hspace"><code>HSpace</code></a>, <a href="../i"><code>I</code></a>, <a href="../image"><code>Image</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../span"><code>Span</code></a>, <a href="../sub"><code>Sub</code></a>, <a href="../sup"><code>Sup</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../value"><code>Value</code></a>

## Elternelemente

<a href="../a"><code>A</code></a>, <a href="../b"><code>B</code></a>, <a href="../case"><code>Case</code></a>, <a href="../color"><code>Color</code></a>, <a href="../fontface"><code>Fontface</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../i"><code>I</code></a>, <a href="../li"><code>Li</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../nobreak"><code>NoBreak</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../overlay"><code>Overlay</code></a>, <a href="../paragraph"><code>Paragraph</code></a>, <a href="../placeobject"><code>PlaceObject</code></a>, <a href="../span"><code>Span</code></a>, <a href="../u"><code>U</code></a>, <a href="../url"><code>URL</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attribute


`bordercolor` (Text, optional, _seit Version 4.15.7_)
: Setze die Rahmenfarbe des links (nur Adobe Acrobat)



`description` (Text, optional, _seit Version 4.19.12_)
: Ein alternativer Text für Barrierefreiheit



`embedded` (Text, optional, _seit Version 4.15.11_)
: Link zu einer eingebetteten Datei. Um eine andere Seite als die erste Seite zu öffnen, setze das page-Attribute auf die Seitenzahl. Um eine named destination anzusteuern, nutze das link-Attribut.



`href` (Text, optional)
: Das Ziel des Hyperlinks. Beispiel: `https://www.speedata.de`



`link` (Text, optional, _seit Version 3.3.8_)
: Das Ziel des Dokumentlinks. Beispiel: `article123`. Ziele werden mit Mark erzeugt. Bei Links auf eingebettete Dateien, kann das link-Attribut den Namen des Ziels beinhalten.



`page` (Zahl, optional, _seit Version 4.3.5_)
: Link zu einer (logischen) Seitenzahl. Bei Links auf eingebettete Dateien, kann das page-Attribut die Seitenzahl des Ziels beinhalten.






## Beispiel


Erzeugt einen Link in einem Dokument auf ein angehängtes Dokument. Wird nur von wenigen PDF Anzeigeprogrammen unterstützt.



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

Erzeugt einen normalen Hyperlink auf eine URL:



```xml
<PlaceObject>
  <Textblock>
    <Paragraph>
      <Value>Siehe die </Value>
      <A href="https://www.speedata.de"><Value>Homepage</Value></A>
      <Value> für weitere Information.</Value>
    </Paragraph>
  </Textblock>
</PlaceObject>

```



