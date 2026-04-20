---
linktitle: "LoadDataset"
weight: 520
type: docs
---

# `LoadDataset`


Load an XML file previously written by [`SaveDataset`]({{% relref "savedataset" %}}) (attribute name) or a well formed XML file (attribute filename). The regular data processing is interrupted and the contents of the data file is taken as a data source. If the file does not exist, the call to [`LoadDataset`]({{% relref "loaddataset" %}}) is ignored.



## Child elements

(none)

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`filename` (text, optional)
: Filename of the XML file to load. Example: `myfile.xml`.



`name` (text, optional)
: Name of the data file. Example: toc






## Example


```xml
<Record element="articles">
  <LoadDataset name="toc"/>
  <ClearPage/>
  <ProcessNode select="article"/>
</Record>

```



