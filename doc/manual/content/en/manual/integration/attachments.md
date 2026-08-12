---
title: "File attachments"
weight: 78
type: docs
---


The PDF file format offers the possibility of embedding files in the document so that they can then be downloaded as stand-alone documents. Electronic invoices, for example, can be sent as a “human-readable” PDF with an attached computer-readable description (as XML).

Any number of files can be attached, but only one ZUGFeRD invoice.

## Attach files

```xml
<AttachFile description="A nice view"
            type="application/pdf"
            filename="ocean.pdf" />
```

This command is used to attach a file to the PDF. The type is the [mime type](https://en.wikipedia.org/wiki/Media_type) of the attached file.

![attachfile.png](/img/attachfile.png)

## Attach ZUGFeRD / Factur-X invoices {{< profeature "Available in the Pro plan" >}}

To attach an electronic invoice, the value at type must be exactly the string `ZUGFeRD invoice`:

```xml
<AttachFile description="Electronic invoice"
            type="ZUGFeRD invoice"
            filename="invoice.xml" />
```

The output filename is set to `factur-x.xml` for ZUGFeRD version 2 and `ZUGFeRD-invoice.xml` for version 1.

The PDF output must be set to PDF/A-3:

```xml
<PDFOptions format="PDF/A-3" />
```

This happens automatically if the command [`<AttachFile>`]({{< relref "/reference/commands/attachfile" >}}) is executed at the beginning of the document (before the first page output).

{{< callout >}}
For a PDF document to be compliant with PDF/A-3, the colors must match the color profiles. In the PDF/A-3 default setting, an OutputIntent is defined for a CMYK color profile. Accordingly, the colors in the document must be defined in this color space. Or another color profile must be embedded.
{{< /callout >}}

![attachfile-zugferd.png](/img/attachfile-zugferd.png)

