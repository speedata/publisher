---
title: Placing objects
weight: 32
type: docs
---


There are two commands to output objects. One is called `<Output>` and is only used for text that is to wrap to multiple pages. All other objects (images, tables, barcodes, ...) are output using the command `<PlaceObject>`.
The parameters are listed in detail in the command reference (see command [`<PlaceObject>`]({{< relref "/reference/placeobject" >}})). Here are some examples and possible applications.

In the simplest case, the command can be used as follows:

```xml
<Record element="data">
  <PlaceObject>
    <Image file="_samplea.pdf" width="5"/>
  </PlaceObject>
</Record>
```

Here an image is loaded with the specified file name and a specified width. The image `_samplea.pdf` (with underscore at the beginning) is included in the distribution and can be used as a placeholder.


## Grid based placement of objects

The [section about grids]({{< relref "/manual/basics/grid" >}}) provides a detailed description of the design grid. Only so much should be mentioned here: The grid helps on the one hand to position the objects (easy arrangement of the objects) and on the other hand to find the right place. Grid cells are not occupied by two objects at the same time, unless you explicitly allow this.

This is an example of grid-based output. The specifications for `row` and `column` are coordinates in the page grid, where the upper left corner is position 1,1.

```xml
<PlaceObject row="4" column="5">
    <Image file="_samplea.pdf" width="5"/>
</PlaceObject>
```


## Order of the objects

The order in which the individual objects are output is important: the objects are drawn on top of each other. This means that objects that are output later overlap the previous objects. This can be useful for background images. In `<AtPageCreation>` you can output a stationery or page header, which is then overwritten with real content in the actual data processing. Or you can include a ready-made page and provide it with the correct page number:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data">
    <PlaceObject row="1" column="1">
      <Image file="termsofservice.pdf" width="180mm" height="280mm"/>
    </PlaceObject>
    <PlaceObject
      column="1"
      row="{sd:number-of-rows()}">
      <Textblock textformat="right">
        <Paragraph>
          <Value select="sd:current-page()"/>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

Here the page is first integrated and then the current page number is "printed" right-justified in the last line.


## Height and width of the objects

Images, barcodes, boxes etc. have fixed widths and heights. Texts and tables use the available width.
That is, the width is the difference between the number of grid cells and the start column plus 1. For an example width of 15 grid boxes and a start column of 6, the text width is 10, unless otherwise specified.

If an object (such as images) requires a width or height specification, this can be given either as an absolute value (e.g. 5cm) or in grid cells.

## Text block
This is a rectangular text area that is not wrapped over multiple pages. Text blocks are ideal for page numbers, short descriptions, column titles and all other units where page breaks are not desired.

A <text block> can contain one or more paragraphs (<paragraph>). Both the text block itself and paragraphs can contain information about the font, colors and text formats used. If these are declared in the paragraphs, they take precedence over those specified in the text block.

```xml
<Textblock color="blue">
  <Paragraph color="green">
    <Value>green text</Value>
  </Paragraph>
  <Paragraph>
    <Value>this text is in blue (given by Textblock)</Value>
  </Paragraph>
</Textblock>
```


Further formatting options are described in the section Including Fonts and Text Formatting.

![Specifications in the paragraphs overwrite the values in the text block](/img/textblock-paragraph.png)

The complete description of `<Textblock>` can be found in the reference (section Text block). For texts that may wrap across page boundaries, there is the command `<Text>` as a child element of `<Output>`, described in the next section.

## Texts with page break

Texts with a page break are not output with <PlaceObject> like the other objects, but with <Output>. The syntax for this is

```xml
<Output>
  <Text>
    <Paragraph>
      <Value>...</Value>
    </Paragraph>
    <Paragraph>
      <Value>...</Value>
    </Paragraph>
  </Text>
</Output>
```

Besides the special feature that this text can wrap around several pages, it is also able to wrap around objects. A detailed description of this property is given in the section Flowing around images.

## HTML

HTML content can be output in different ways. The simplest is to use the `<HTML>` command directly within `<Output>`:

```xml
<Output>
  <HTML>
    <p>A paragraph with <b>bold</b> and <i>italic</i> text.</p>
  </HTML>
</Output>
```

HTML can also be used within `<Paragraph>` in a `<Textblock>` or `<Text>`. In this case, the HTML comes from the data:

```xml
<Record element="Paragraph">
  <PlaceObject>
    <Textblock>
      <Paragraph>
        <Value select="." />
      </Paragraph>
    </Textblock>
  </PlaceObject>
</Record>
```

With data like:

```xml
<Paragraph><![CDATA[<ul><li>Item 1</li><li>Item 2</li></ul>]]></Paragraph>
```

A detailed description of the HTML features including CSS styling is given in the section [HTML]({{< relref "/manual/webformats/html" >}}).

## Introduction to tables

The table model used in the Publisher corresponds approximately to the model known from HTML.
The rows are specified with `<Tr>` and the individual columns with `<Td>`.

The structure of a simple table without column declaration, header and footer looks as follows:

```xml
<PlaceObject>
  <Table>
    <Tr>
      <Td>...</Td>
      <Td>...</Td>
    </Tr>
    <Tr>
      <Td>...</Td>
      <Td>...</Td>
    </Tr>
  </Table>
</PlaceObject>
```

The contents of the table cells can be paragraphs, pictures and other objects.

```xml
<Td>
  <Paragraph>
    <Value>...</Value>
  </Paragraph>
</Td>

<Td>
  <Image file="ocean.pdf" width="4"/>
</Td>
```

A practical feature of tables is that they can run over several pages, even with repeating headers and footers.
The table cells can contain text, images, barcodes, etc.; in other words, anything that can also be contained in `<PlaceObject>`.
Individual cells are never wrapped to multiple pages, i.e. they are set as a rectangular box, even if the contents would allow wrapping (e.g. texts or tables).

A separate chapter is devoted to the topic of tables [a separate chapter]({{< relref "tables" >}}).

## Images

Including images is, as already shown at the beginning, very easy. The command for this is `<Image>`:

```xml
<PlaceObject>
    <Image file="_samplea.pdf" width="5cm"/>
</PlaceObject>
```

Images can be in the formats PDF, JPEG and PNG and can be integrated. All other formats such as Tiff or SVG must be converted first.

The command for embedding images is very powerful and is described in detail in a separate section ([Image inclusion]({{< relref "imagesandgraphics" >}})). The [reference]({{< relref "/reference/image" >}}) contains a short description of all possibilities.

## Rectangular areas (`<Box>`)

Rectangular surfaces are created with the command <Box>.

```xml
<PlaceObject>
  <Box width="4" height="3" background-color="limegreen"/>
</PlaceObject>
```

![A colored box, output with `<Box>`](/img/zitronengruen.png)

Boxes are often used for colored areas behind a text or table. In this case the allocation of the raster cells must be switched off (`allocate="no"` at `<PlaceObject>`), otherwise a warning will be issued because of the double allocation of the area in the PDF (see section [Grid]({{< relref "/manual/basics/grid" >}})). An example for the use of boxes as background can be found in the section about crop marks. There, the parameter bleed is also explained, which is used to enlarge the box in one or more directions, if they are located at the page margin.

## Circle

Circles are output with the command `<Circle>`:

```xml
<Record element="data">
  <PlaceObject column="5" row="5">
    <Circle radiusx="3" background-color="goldenrod"/>
  </PlaceObject>
  <PlaceObject column="5" row="5">
    <Circle radiusx="1pt" background-color="black"/>
  </PlaceObject>
</Record>
```

In this example the radius of the large circle is 3 grid boxes and the center of the circle is in the upper left corner of the box (5.5). So it starts in the second column and the second row and extends to the seventh column and row. Circles have the special property that no grid cells are marked as allocated.

![Circle with radius 3 and center at (5,5)](/img/kreismitmittelpunkt.png)

## Rules

There are horizontal and vertical rules. These can have a thickness, a color and a length. Rules can be solid and dashed:

```xml
<PlaceObject column="2" row="2">
  <Rule direction="horizontal" length="4" dashed="yes"/>
</PlaceObject>
```

Rules are always aligned in the upper left corner of the box.

![A dashed rule.](/img/gestricheltelinie.png)

## Frame

The frame (like the transformation below) is a special object that you place over another object. A frame (`<Frame>`) always contains another object, for example a picture.

```xml
<PlaceObject>
  <Frame
    border-bottom-left-radius="8pt"
    border-bottom-right-radius="8pt"
    border-top-left-radius="8pt"
    border-top-right-radius="8pt"
    framecolor="darkseagreen"
    rulewidth="2pt">
    <Image file="_samplea.pdf" width="4"/>
  </Frame>
</PlaceObject>
```

You can see that the frame works as a clipping path, the parts outside are hidden. You can also set the rulewidth to zero and make it invisible, then only the content will be clipped.

![Frame with radius 8pt and line width of 2 points.](/img/eagle-frame.png)

## Transformation

![The four basic transformations (from the PDF specification)](/img/transformation.png)

Like the frame, the transformation is an enclosing element. This means that the element must still have a content, such as an image.

In the transformation, you specify a matrix consisting of six numbers in the form "a b c d e f". The transformation from one coordinate system to another is mapped using the following 3x3 matrix:

$$
\begin{bmatrix} x' & y' & 1 \end{bmatrix} = \begin{bmatrix} x & y & 1 \end{bmatrix} \times \begin{bmatrix} a & b & 0 \\ c & d & 0 \\ e & f & 1 \end{bmatrix}
$$

If you want to calculate the new coordinates x' and y' from the coordinates x and y, you can also do this using the following formulas:

$$
\begin{aligned}
x' &= a \times x + c \times y + e \\
y' &= b \times x + d \times y + f
\end{aligned}
$$

There are the following basic transformation types (see figure The four basic transformations (from the PDF specification))

1. Displacements (translation) are described with the values \(1\; 0\; 0\; 1\; t_x\; t_y\). Scaling is specified with \(s_x\; 0\; 0\; s_y\; 0\; 0\)
2. Rotation can be achieved with \(\cos\theta\; \sin\theta\; {-\sin\theta}\; \cos\theta\; 0\; 0\)
3. Displacements (skew) are described with \(1\; \tan\alpha\; \tan\beta\; 1\; 0\; 0\)
4. The identity transformation is \(1\; 0\; 0\; 1\; 0\; 0\).

```xml
<PlaceObject>
  <Transformation matrix="1.8 0.2 0.2 0.8 0 0 ">
    <Image file="ocean.pdf" width="4"/>
  </Transformation>
</PlaceObject>
```

![Shifting and scaling by the transformation matrix.](/img/eagle-transform.png)

## Flipping objects

Objects can also be mirrored using the Transformation command. This can be controlled either with the transformation matrix or with the ‘flip’ attribute:

```xml
<PlaceObject>
    <Transformation flip="vertical">
        <Image width="3cm" file="ocean.pdf" />
    </Transformation>
</PlaceObject>
```

The allowed attributes are `none`, `horizontal`, `vertical` and `both`.

## Barcodes, QR Codes {{< profeature "Available in the Pro plan" >}}

Barcodes or QR codes are integrated via the command `<Barcode>`:

```xml
<PlaceObject>
  <Barcode select="'Hello world'" type="QRCode" width="5"/>
</PlaceObject>
```

The output is as expected

![Hello World in pixels](/img/qrcode-hallowelt.png)

Barcodes in the coding "EAN13" and "Code 128" can be output.

## Clipping

Since version 4.11.3 the speedata Publisher can clip any kind of objects. The new object is smaller than the original object if the method is clip (`method=clip`, the default) is selected, otherwise (`method=frame`) the resulting object has the original size but the visible portion of the image is set to the clipping path.

A user came up with a very good description of the differences between the methods `clip` and `frame`:

If _Publisher_ had scissors, “clip” would cut the image itself, while “frame” would cut a frame to be placed on top of the image (enabling partial display).

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">
  <Pageformat height="14cm" width="11cm" />

  <Record element="data">
    <PlaceObject>
      <Clip left="1cm" right="1cm" top="1cm" bottom="2cm" method="clip">
        <Image width="5cm" file="_sampleb.pdf" />
      </Clip>
    </PlaceObject>
    <PlaceObject column="5" >
      <Image width="5cm" file="_sampleb.pdf" />
    </PlaceObject>
  </Record>
</Layout>
```

![A clipped and a non-clipped image.](/img/outputobjects-clip.png)

