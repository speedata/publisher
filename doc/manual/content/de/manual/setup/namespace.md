---
title: "Namensraum des Layoutregelwerks"
linkTitle: "Namensraum"
weight: 50
type: docs
---

Der XML-Namensraum des Layoutregelwerks ist `urn:speedata.de:2009/publisher/en`.
Die zusätzlichen XPath-Funktionen liegen im Namensraum `urn:speedata:2009/publisher/functions/en`.
Daher sollte ein Layoutregelwerk immer diesen Rahmen haben:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
        xmlns:sd="urn:speedata:2009/publisher/functions/en">
 ...
</Layout>
```

Dann lassen sich die speedata-eigenen Funktionen mit dem Präfix `sd:` aufrufen, zum Beispiel: `sd:current-page()` um die aktuelle Seitenzahl zu ermitteln.
