---
linktitle: "AttachFile"
weight: 60
type: docs
---

# `AttachFile`
_since version 3.1.1_

Attach a file to the PDF. Can be used to attach a ZUGFeRD electronic invoice.



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`description` (text, optional)
: Textual description of the attached file (for the PDF viewer).



`filename` (text, optional)
: The name of the local file to be attached to the PDF.



`name` (text, optional, _since version 3.7.3_)
: Set the name of the attached file in the PDF document. Defaults to `factur-x.xml` if the attached file type is `ZUGFeRD invoice`.



`select` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}), optional, _since version 3.7.2_)
: The contents of the file. Alternative to reading a file from the hard-drive.



`type` (text)
: The type of the included file. Must be a mime type or `ZUGFeRD invoice`.






## Example


```xml
<AttachFile filename="invoice.xml" description="A ZUGFeRD invoice." type="ZUGFeRD invoice"/>
```

```xml
<AttachFile select="CrossIndustryDocument" description="A ZUGFeRD invoice." type="ZUGFeRD invoice"/>
```



## Info


Attaching a ZUGFeRD electronic invoice is available in the Pro plan.




