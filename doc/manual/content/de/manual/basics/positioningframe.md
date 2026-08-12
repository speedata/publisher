---
title: "Platzierungsbereiche"
weight: 41
type: docs
---


Die Seiten kann man in virtuelle Bereiche unterteilen. Dazu gibt man im Seitentyp (Pagetype) Rahmen an:

```xml
<Pagetype name="seite" test="true()">
  <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
  <PositioningArea name="pagehead">
    <PositioningFrame width="19" height="2" row="1" column="1"/>
  </PositioningArea>
  <PositioningArea name="left">
    <PositioningFrame width="4" height="{sd:number-of-rows() - 3}" row="4" column="2"/>
  </PositioningArea>
  <PositioningArea name="text">
    <PositioningFrame width="10" height="{sd:number-of-rows() - 3}" row="4" column="8"/>
  </PositioningArea>
</Pagetype>
```

Hier werden drei Bereiche definiert, die man mit dem Attribut `area="..."` ansprechen kann, wenn es um die Ausgabe von Objekten oder um die Verschiebung des Cursors geht:

```xml
<Record element="data">
  <PlaceObject area="pagehead">
    <Textblock>
      <Paragraph>
        <Value>pagehead, height of the area: </Value>
        <Value select="sd:number-of-rows('pagehead')"></Value>
      </Paragraph>
    </Textblock>
  </PlaceObject>
  <PlaceObject area="left">
    <Textblock>
      <Paragraph>
        <Value>left, height: </Value>
        <Value select="sd:number-of-rows('left')"></Value>
      </Paragraph>
    </Textblock>
  </PlaceObject>
  <PlaceObject area="text">
    <Textblock>
      <Paragraph>
        <Value>text, width: </Value>
        <Value select="sd:number-of-columns('text')"></Value>
      </Paragraph>
    </Textblock>
  </PlaceObject>
</Record>
```

![Die Bereiche der Seite werden mit area="..." angesprochen. Manche Layoutfunktionen erlauben die Angabe eines Bereichs.](/img/positioningareas.png)

## Cursor

Der Cursor ist eine virtuelle Markierung, die nach jeder Ausgabe im Raster verschoben wird, sofern es nicht explizit unterbunden wird (`keepposition="yes"` bei `<PlaceObject>`).
Die Markierung ist für jeden Bereich separat gesteuert. D. h. eine Ausgabe in einem Bereich hat keine Änderung des Cursors in einem anderen Bereich zur Folge.
Wird ein Objekt ausgegeben, das bis zum rechten Rand reicht, springt der Cursor automatisch in die nächste freie Zeile.
Der Cursor kann zeilenweise mit `<NextRow>` verschoben werden.
Bei der Angabe von `rows="n"` wird der Cursor um n Zeilen tiefer gesetzt.
Bei der Angabe von `row="n"`  wird der Cursor in Zeile n gesetzt.

Folgendes Beispiel illustriert das Verhalten des Cursors.

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Trace grid="yes"/>

  <Record element="data">
    <!--1-->
    <PlaceObject>
      <Box width="{sd:number-of-columns()}" height="1"/>
    </PlaceObject>
    <NextRow rows="1" />
    <PlaceObject>
      <Box width="{sd:number-of-columns()}" height="1"/>
    </PlaceObject>

    <NextRow rows="2" />

    <PlaceObject>
      <Box width="4" height="1"/>
    </PlaceObject>
    <!--2-->
    <NextRow rows="1" />
    <PlaceObject>
      <Box width="4" height="1"/>
    </PlaceObject>

  </Record>
</Layout>
```
1. Die beiden Objekte gehen über die gesamte Breite. Der Cursor springt automatisch in die nächste Zeile, sobald er hinter dem rechten Rand ist. Durch das `<NextRow>` entsteht die freie Zeile.
2. Der Cursor ist nun in Zeile 6 und Spalte 5. Der folgende Zeilenvorschub setzt den Cursor in Zeile 7 und Spalte 1.


![Das Verhalten von NextRow](/img/cursor.png)

## Überlauf von Texten in den nächsten Rahmen

Mit der Ausgabe von Texten über die Befehle `<Output>`/`<Text>` können Seitenumbrüche in Texten vorkommen, wie im Abschnitt [Objekte ausgeben]({{< relref "outputtingobjects" >}}) beschrieben.
Das funktioniert nicht nur über Seitengrenzen, sondern auch über Bereiche auf den Seiten, sofern diese denselben Namen haben.

Als Beispiel dient diese Seitendefinition:

```xml
  <Pagetype name="page" test="true()">
    <Margin left="1cm" right="1cm" top="1cm" bottom="1cm"/>
    <PositioningArea name="text">
      <PositioningFrame width="4" height="17" row="2" column="1"/>
      <PositioningFrame width="4" height="10" row="3" column="6"/>
      <PositioningFrame width="4" height="24" row="1" column="11"/>
    </PositioningArea>
  </Pagetype>
```

Die Ausgabe wird über `<Output>` erzeugt:

```xml
    <Output area="text">
      <Text>
        <Paragraph>
          <Value select="sd:dummytext(3)"/>
        </Paragraph>
      </Text>
    </Output>
```

![Der Text fließt automatisch in den nächsten freien Bereich. Falls notwendig, wird ein Seitenumbruch eingefügt.](/img/textoverflow.png)

Man kann auch den Wechsel eines Rahmens erzwingen. Mit `<NextFrame>` und der Angabe eines Bereiches (`area="..."`) wird der Cursor oben links in den nächsten Rahmen gesetzt, ggf. wird ein Seitenumbruch eingefügt.

