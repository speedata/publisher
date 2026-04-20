---
linktitle: "Groupcontents"
weight: 400
type: docs
---

# `Groupcontents`
_since version 2.9.10_

Insert the contents of a group (a virtual area)



## Child elements

(none)

## Parent elements

<a href="../td"><code>Td</code></a>

## Attributes


`name` (text)
: The name of the group






## Example


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



