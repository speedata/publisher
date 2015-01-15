title: CSS
---

CSS im speedata Publisher
=========================

_Hinweis: Die Unterstützung von CSS wurde in Version 2.2 eingeführt. Es handelt sich zu dem Zeitpunkt mehr um einen Proof-of-Concept als um eine vollständige Implementierung. Möglicherweise wird sich die Syntax oder die Schnittstelle zu den Befehlen in zukünftigen Versionen verändern! Bitte bei Bedarf anfragen._

Laden eines Stylesheets bzw. deklarieren der CSS-Regeln
--------------------------------------------------------

Im Publisher kann mit der Stylesheet-Anweisung eine CSS-Datei geladen werden bzw. innerhalb einer Stylesheet-Anweisung können CSS-Regeln deklariert werden:

    <Stylesheet dateiname="regeln.css"/>


oder

    <Stylesheet>
      td {
        vertical-align: top ;
      }
    </Stylesheet>

Mit diesen Regeln lassen sich einige der Befehle (derzeit `Absatz`, `Box`,
`Rahmen`, `Tlinie`, `Td`) im Aussehen anpassen. Wie bei CSS üblich können die
Eigenschaften über die Id, Klasse und über den Befehlsnamen angesprochen
werden.

So bewirken für diese Tabelle:

    <ObjektAusgeben>
      <Tabelle>
        <Tr minhöhe="4">
          <Td class="myclass" id="myid"><Absatz><Wert>Hallo Welt</Wert></Absatz></Td>
        </Tr>
      </Tabelle>
    </ObjektAusgeben>

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



