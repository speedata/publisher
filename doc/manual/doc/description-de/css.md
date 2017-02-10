title: CSS
---

CSS im speedata Publisher
=========================

_Hinweis: Die Unterstützung von CSS wurde in Version 2.2 eingeführt. Es handelt sich zu dem Zeitpunkt mehr um einen Proof-of-Concept als um eine vollständige Implementierung. Möglicherweise wird sich die Syntax oder die Schnittstelle zu den Befehlen in zukünftigen Versionen verändern! Bitte bei Bedarf anfragen._

Laden eines Stylesheets bzw. deklarieren der CSS-Regeln
--------------------------------------------------------

Im Publisher kann mit der Stylesheet-Anweisung eine CSS-Datei geladen werden bzw. innerhalb einer Stylesheet-Anweisung können CSS-Regeln deklariert werden:

    <Stylesheet filename="regeln.css"/>


oder

    <Stylesheet>
      td {
        vertical-align: top ;
      }
    </Stylesheet>

Mit diesen Regeln lassen sich einige der Befehle (derzeit `Paragraph`, `Box`,
`Rule`, `Frame`, `Tablerule`, `Td`) im Aussehen anpassen. Wie bei CSS üblich,
können die Eigenschaften über die Id, Klasse und über den Befehlsnamen
angesprochen werden.

So bewirken für diese Tabelle:

    <PlaceObject>
      <Table>
        <Tr minheight="4">
          <Td class="myclass" id="myid"><Paragraph><Value>Hallo Welt</Value></Paragraph></Td>
        </Tr>
      </Table>
    </PlaceObject>

alle folgenden CSS-Anweisungen dasselbe

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

und

    td {
      vertical-align: top ;
    }


Die Zuordnung vom Befehlsnamen in den CSS-Anweisungen und im Layout-Regelwerk sind im Handbuch in der Befehlsreferenz dokumentiert.

Zugriff auf die Daten mit CSS
-----------------------------

Wenn die Daten z.B in folgender Form vorliegen:

    <data>hello <green>green</green> world <br/>with a <span class="blue">span</span>.</data>

kann man mit folgendem Stylesheet die gewünschten Farben erzeugen:

    <Stylesheet>
      green {
        color: green;
      }
      .blue {
        color: blue;
      }
    </Stylesheet>



