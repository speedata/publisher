---
title: "Umfließen von Bildern"
weight: 51
type: docs
---


Text, der über den Befehl `<Output allocate="auto">` ausgegeben wird, umfließt zuvor platzierte Objekte. Es bietet sich daher an, Objekte, die umflossen werden sollen, zuerst auch auf zukünftige Seiten zu platzieren. Das erreicht man mit dem Attribut `page` im Befehl `<PlaceObject>`.
In dem Attribut muss man entweder eine konkrete Seitenzahl oder `next` für die nächste Seite angeben.
Damit der Cursor bei der Ausgabe nicht verändert wird, empfiehlt es sich, das Attribut `keepposition` auf `yes` zu setzen.

Das vollständige Beispiel ist unter https://github.com/speedata/examples/tree/master/technical/wraparoundobjects zu finden.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <SetGrid height="12pt" nx="10"/>

  <Pageformat width="180mm" height="90mm"/>
  <DefineTextformat name="text" orphan="yes" widow="yes"/>

  <LoadFontfile name="RedactedScript"
                filename="redacted-script-regular.ttf"/>
  <DefineFontfamily name="text" fontsize="10" leading="12">
    <Regular fontface="RedactedScript"/>
  </DefineFontfamily>

  <Record element="data">
    <PlaceObject column="8" row="1" keepposition="yes">
      <Box width="3" height="6"
           background-color="thistle" padding-left="2mm"
           padding-bottom="2mm"/>
    </PlaceObject>

    <PlaceObject column="1" row="12" keepposition="yes">
      <Box width="3" height="6"
           background-color="lightgreen" padding-top="2mm"
           padding-right="2mm"/>
    </PlaceObject>

    <Output allocate="auto" row="1">
      <Text>
        <Loop select="3">
          <Paragraph>
            <Value select="sd:dummytext()"/>
          </Paragraph>
        </Loop>
      </Text>
    </Output>
  </Record>
</Layout>
```

![Automatisches Umfließen von Objekten, die vorher ausgegeben wurden.](/img/umfliessenvonbildern.png)

## Komplexe Formen

Es ist möglich, Umrisse von Bildern mit nicht-rechteckigen Formen zu erstellen.
Dazu gibt man einer Bilddatei eine in XML formulierte Umrissdatei mit.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <SetGrid height="12pt" width="4mm"/>

  <Pagetype name="page" test="true()">
    <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
    <PositioningArea name="text">
      <PositioningFrame width="20" height="20" row="1" column="1"/>
    </PositioningArea>
  </Pagetype>

  <Record element="data">
    <PlaceObject column="16" row="1" keepposition="yes">
      <Image file="pocketwatch.pdf"/>
    </PlaceObject>

    <Output allocate="auto" row="1" area="text">
      <Text>
        <Loop select="3">
          <Paragraph>
            <Value select="sd:dummytext()"/>
          </Paragraph>
        </Loop>
      </Text>
    </Output>
  </Record>
</Layout>
```

Die Datei `taschenuhr.pdf` kann eine Umrissdatei mit demselben Namen und der Endung `xml` haben, die wie folgt aufgebaut ist:

```xml
<imageinfo>
  <cells_x>75</cells_x>
  <cells_y>100</cells_y>
  <segment x1="35" x2="40" y1="5" y2="5"/>
  <segment x1="33" x2="42" y1="6" y2="6"/>
  <segment x1="31" x2="44" y1="7" y2="7"/>
  <segment x1="30" x2="45" y1="8" y2="8"/>
  ...
  <segment x1="30" x2="46" y1="95" y2="95"/>
  <segment x1="33" x2="43" y1="96" y2="96"/>
</imageinfo>
```
{{% codecaption %}}Die Segmente bestimmen den belegten Bereich. Die Angaben beziehen sich auf die (willkürliche) Maßeinheit von 75x100 Einheiten.{{% /codecaption %}}

![Die Form der Uhr muss in einem vorbereitenden Schritt ermittelt werden.](/img/taschenuhr.png)

{{< callout >}}
Diese Funktionalität ist noch experimentell. Die nächsten Versionen des Publishers haben wahrscheinlich Verbesserungen bei diesem Feature. Der Umriss eines Bildes kann mit dem Programm `imageshaper` unter <https://github.com/speedata/imageshaper> erzeugt werden.
{{< /callout >}}

Ein vollständiges Beispiel ist unter https://github.com/speedata/examples/tree/master/imageshape zu finden.

