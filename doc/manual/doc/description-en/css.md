title: CSS
---

Using CSS with the speedata Publisher
=====================================

_Remark: The support of CSS was introduced in version 2.2. At that time, it is more a proof-of-concept than a full implementation. The interface might change in the future. When in doubt, just ask._

Loading a stylesheet and declaring CSS rules
--------------------------------------------

CSS stylesheets are defined with the command `Stylesheet`:



    <Stylesheet filename="rules.css"/>


or

    <Stylesheet>
      td {
        vertical-align: top ;
      }
    </Stylesheet>

With these rules, some of the XML elements in the layout stylesheet (currently `Box`, `Frame`, `Rule`, `Paragraph`, `Tablerule`, `Td`) can be styled. As it is common with CSS, you can set the properties with the class name, the id and the command name.

For this table

    <PlaceObject>
      <Table>
        <Tr minheight="4">
          <Td class="myclass" id="myid"><Paragraph><Value>Hello world</Value></Paragraph></Td>
        </Tr>
      </Table>
    </PlaceObject>

each of the following CSS declarations have the same effect:

````
#myid {
  vertical-align: top ;
}
````

````
.myclass {
  vertical-align: top ;
}
````

and

    td {
      vertical-align: top ;
    }

The mapping of the command names for the CSS rules and the layout rules are documented in the reference manual.

Accessing the data with CSS
-----------------------------

If the data is in the following format:

    <data>hello <green>green</green> world <br/>with a <span class="blue">span</span>.</data>

you can get the desired colors with the following stylesheet:

    <Stylesheet>
      green {
        color: green;
      }
      .blue {
        color: blue;
      }
    </Stylesheet>


