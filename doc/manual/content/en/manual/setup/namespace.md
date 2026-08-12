---
title: "Namespace of the layout ruleset"
linkTitle: "Namespace"
weight: 50
type: docs
---

The XML namespace of the layout ruleset is `urn:speedata.de:2009/publisher/en`. The additional XPath functions are in the namespace `urn:speedata:2009/publisher/functions/en`. A layout ruleset should therefore always have this frame:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
        xmlns:sd="urn:speedata:2009/publisher/functions/en">
 ...
</Layout>
```

Then you can call speedata's own functions with the prefix `sd:`, for example: `sd:current-page()` to determine the current page number.
