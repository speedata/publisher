---
title: "Rotation of contents"
weight: 52
type: docs
---



Objects that are output with `<PlaceObject>` can be rotated.
For this purpose, there is the attribute `rotate`, which expects an angle (in degrees), whereas positive values cause a clockwise rotation.

```xml
    <PlaceObject rotate="10">
      <Image file="_sampleb.pdf" width="3"/>
    </PlaceObject>
```

When an object is rotated, you need to specify the point around which it should rotate.
The default setting is the upper left corner.
With the attributes `origin-x` (`left`, `center` and `right`) and `origin-y` (`top`, `center`, `bottom`) you can define the axis of rotation.
In addition to these values, numbers from 0 to 100 are also possible, the upper left corner is 0, 0 and the lower right corner is 100, 100.

![The image is rotated by 10 degrees. A negative value would make the rotation counterclockwise.](/img/rotieren.png)

{{< callout >}}
In [examples repository on github](https://github.com/speedata/examples/) there is a document in the `technical` directory which shows the effect of `origin-x` and `origin-y`.
{{< /callout >}}


## Rotate images

The attribute `rotate` is available for both `<PlaceObject>` and `<Image>`. The attribute at `<Image>` can only rotate images in 90 degree steps (positive values: clockwise). Therefore, in practice the rotation is rather controlled by `<PlaceObject>`.
This minimal sample shows the difference:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Record element="data">
    <PlaceObject rotate="-90">
      <Image file="_sampleb.pdf" width="3cm"/>
    </PlaceObject>
    <ClearPage/>
    <PlaceObject>
      <Image file="_sampleb.pdf" width="3cm"  rotate="-90"/>
    </PlaceObject>
  </Record>
</Layout>
```

Bear in mind that this rotation might also affect some given image dimensions.

The following example rotates an image 90 degrees counterclockwise if it is a portrait image.
With the XPath command `sd:aspectratio(<filename>)` you can determine the aspect ratio of an image.
If it is greater than 1, then it is a landscape image.
The second image from the data file is rotated by 90° counterclockwise.

```xml
<data>
  <img file="_samplea.pdf" />
  <img file="_sampleb.pdf" />
</data>
```
{{% codecaption %}}Data{{% /codecaption %}}

```xml
<Layout xmlns:sd="urn:speedata:2009/publisher/functions/en"
  xmlns="urn:speedata.de:2009/publisher/en">

  <Record element="data">
    <ForAll select="img">
      <PlaceObject>
        <Image file="{@file}" width="5"
          rotate="{if ( sd:aspectratio(@file) &lt; 1 ) then '-90' else '0'}"/>
      </PlaceObject>
    </ForAll>
  </Record>
</Layout>
```
{{% codecaption %}}The image is rotated 90 degrees if it is a portrait image.{{% /codecaption %}}

![The second image is rotated by 90° because it is in portrait format.](/img/drehungaspectratio.png)

{{< callout >}}
The curly brackets at `file` and `rotate` mean that the system jumps to XPath mode to evaluate the XPath expressions (access to the file attribute and the if-then query). See [XPath and Layout Functions]({{< relref "/reference/xpath/xpath" >}}) for more information.
{{< /callout >}}

_Note: if the image in the argument of `sd:aspectratio()` is not available in the filesystem, the value is taken from the placeholder image (section [Image not found?]({{< relref "/manual/imagesandgraphics#image-not-found" >}})). To check if an image is available at all, you can use the command `sd:file-exists(<filename>)`._

## Rotate via transformation

Using the command `<Transformation>` (see section [Transformation]({{< relref "outputtingobjects#transformation" >}}) and in the reference the [command description]({{< relref "/reference/commands/transformation" >}})) you can also rotate contents.
The matrix has the form "cos θ sin θ -sin θ cos θ 0 0", for a rotation of 90 degrees thus "0 1 -1 0 0 0".
This is shown in the section [Image behind the text]({{< relref "/manual/tables#image-behind-the-text" >}}).

