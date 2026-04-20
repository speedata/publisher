---
linktitle: "Groupcontents"
weight: 400
type: docs
---

# `Groupcontents`
_seit Version 2.9.10_

Fügt den Inhalt der Gruppe ein (einer virtuellen Fläche)



## Kindelemente

(keine)

## Elternelemente

<a href="../td"><code>Td</code></a>

## Attribute


`name` (Text)
: Der Name der Gruppe






## Beispiel


```xml
<Record element="data">
  <Group name="foo">
    <Contents>
      <PlaceObject column="1">
        <Image file="_samplea.pdf" width="5"/>
      </PlaceObject>
    </Contents>
  </Group>
  <PlaceObject>
    <Table>
      <Tr>
        <Td><Groupcontents name="foo"/></Td>
      </Tr>
    </Table>
  </PlaceObject>
</Record>

```



