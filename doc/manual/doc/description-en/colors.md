title: Using colors with the speedata Publisher
---
Using colors with the speedata Publisher
========================================

Almost all objects that can be output with the publisher can take a color. The color is declared at the object that gets rendered or within a CSS stylesheet. Here is an example for a direct color declaration at the object:


    <PlaceObject>
      <Box width="5" height="2" backgroundcolor="background"/>
    </PlaceObject>

Here it is defined indirectly via CSS:


    <Stylesheet>
      box {
        background-color: background;
      }
    </Stylesheet>
    ...
    <Record element="data">
      <PlaceObject>
        <Box width="5" height="2" />
      </PlaceObject>
    </Record>


In both cases the color “background” has to be defined previously, for example with:

    <DefineColor name="background" model="cmyk" c="97" m="77" y="0" k="3"/>

There are other methods for color selection. See the following sections.

Direct usage of CSS-level-3 colors
----------------------------------

The standard CSS colors (see the command [DefineColor](../commands-en/definecolor.html)) are predefined, although in the RGB color space. This color space only suited for on screen presentation. With the predefined colors you can use a command like this without further color declarations:

    <PlaceObject>
      <Box width="5" height="2" backgroundcolor="goldenrod" />
    </PlaceObject>


Direct usage of CSS RGB values
------------------------------

The color values can be given with the HTML/CSS hash values:

    <PlaceObject>
      <Box width="5" height="2" backgroundcolor="#DAA520" />
    </PlaceObject>

Indirect color definition
------------------------

The indirect color definition is shown in the first example above. It is useful when the color should have a symbolic name.

    <DefineColor name="background" model="cmyk" c="97" m="77" y="0" k="3"/>
    <DefineColor name="foreground" model="cmyk" c="2" m="12" y="59" k="1"/>


Color spaces
------------

There are different color spaces in which colors can be defined. For screen presentation the RGB color space is usually used, as it maps to the red, green and blue pixels of the screen. It is not suitable for print, as the printing colors are normally placed on white paper where the light is subtracted by the colors cyan, magenta, yellow and black. For print you use the color space CMYK. In theory it is easily possible to convert RGB colors to CMYK colors, but in practice it highly depends on the material that is used in the printing process. Other commonly used color spaces are gray values and spot colors such as HKS and Pantone.

Spot colors
-----------

In contrast to colors from the RGB colorspace, the spot colors (such as
Pantone or HKS) can only be used indirectly with the speedata Publisher. One
of the problems that occur with spot colors is, that it is impossible to show
a spot color on screen. Every such color has a CMYK substitute which is used
when  the spot color is not available (screen or 4 color print).

For the common Pantone colors the substitutions are predefined. The following color definition is sufficient to use Pantone 115 C for printing and on screen rendering.

    <DefineColor name="background" model="spotcolor" colorname="PANTONE 115 C"/>


Own colors have to be defined as follows:


    <DefineColor name="background" model="spotcolor" colorname="Coat" c="12" m="8" y="20" k="0" />


Overprinting
------------

Indirectly defined colors can have the property “overprint”. This is in
instruction to the raster image processor (RIP) (not) to erase the underlying
colors. If enabled (`overprint="yes"`), objects with this color are printed on
top of the colors of the objects “below” that object. The default is “no”,
which means that the visible color is always from the top most object. This is
only available on supported output devices.





