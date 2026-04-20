---
linktitle: "Message"
weight: 580
type: docs
---

# `Message`


Writes a message onto the console and to the protocol file.



## Child elements

<a href="../element"><code>Element</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../atpagecreation"><code>AtPageCreation</code></a>, <a href="../atpageshipout"><code>AtPageShipout</code></a>, <a href="../case"><code>Case</code></a>, <a href="../contents"><code>Contents</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../layout"><code>Layout</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../record"><code>Record</code></a>, <a href="../savepages"><code>SavePages</code></a>, <a href="../section"><code>Section</code></a>, <a href="../table"><code>Table</code></a>, <a href="../tr"><code>Tr</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes


`error` (optional)
: Generate an error besides writing the message.


  - `yes`: Report an error.
  - `no`: Do not report an error (default).

`errorcode` (number, optional, _since version 2.3.69_)
: If an error is raised, use this code on exit. Defaults to 1. Negative values are reserved for system purpose.



`exit` (optional, _since version 3.1.17_)
: Tells the software to exit immediately.


  - `no`: The speedata Publisher continues with the PDF creation.
  - `yes`: The speedata Publisher exits without finishing the PDF file.

`select` ([XPath expression]({{% relref "../manual/xpathref/xpath" %}}), optional)
: Contents of the message. You can alternatively specify the message by the child elements [`Value`]({{% relref "value" %}}).






## Example




