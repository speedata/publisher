---
linktitle: "Columns"
weight: 210
type: docs
---

# `Columns`


Set the widths and other properties of the columns in a table.



## Child elements

<a href="../column"><code>Column</code></a>, <a href="../copy-of"><code>Copy-of</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../switch"><code>Switch</code></a>, <a href="../value"><code>Value</code></a>

## Parent elements

<a href="../case"><code>Case</code></a>, <a href="../forall"><code>ForAll</code></a>, <a href="../function"><code>Function</code></a>, <a href="../loop"><code>Loop</code></a>, <a href="../otherwise"><code>Otherwise</code></a>, <a href="../setvariable"><code>SetVariable</code></a>, <a href="../table"><code>Table</code></a>, <a href="../until"><code>Until</code></a>, <a href="../while"><code>While</code></a>

## Attributes
(none)


## Remarks

The `*` widths in the command “Column” allow dynamic cell widths. For that the total width of the table must be set and the attribute (on [`Table`]({{% relref "table" %}})) `stretch` must be set to `max`.
        The widths of the columns are calculated as follows: first the absolute widths are taken into account. After that, the `*` columns are distributed across the remaining space. The
        numbers before the `*` denote the fraction of the space. In the example below the third column gets 1/6 of the remaining width, the fourth column get 5/6.




## Example


```xml
<Table>
  <Columns>
    <Column width="14mm" />
    <Column width="2" />
    <Column width="1*" align="right" valign="top" />
    <Column width="5*" />
    <Column width="5mm" background-color="gray" />
    <Tr>
       ....
    </Tr>
  </Columns>
</Table>

```



