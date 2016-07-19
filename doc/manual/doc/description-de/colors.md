title: Farben im speedata Publisher
---
Benutzung von Farben im speedata Publisher
==========================================

Fast alle Objekte, die im Publisher ausgegeben werden, können eine Farbe annehmen. Üblicherweise wird die Farbe bei dem Objekt selbst angegeben oder über CSS-Stylesheets gesteuert. Hier ein Beispiel für die direkte Farbgebung bei dem Objekt:

    <PlaceObject>
      <Box width="5" height="2" backgroundcolor="Dunkelblau" />
    </PlaceObject>

Oder sie wird indirekt per CSS festgelegt:


    <Stylesheet>
      box {
         background-color: Dunkelblau;
      }
    </Stylesheet>
    ...
    <Record element="data">
      <PlaceObject>
        <Box width="5" height="2" />
      </PlaceObject>
    </Record>

In beiden Fällen muss die Farbe »Dunkelblau« vorher festgelegt werden, z.B. mit:

    <DefineColor name="Dunkelblau" model="cmyk" c="97" m="77" y="0" k="3"/>

Es gibt noch andere Methoden der Farbselektion.


Direkte Nutzung von CSS-Level-3 Farben
---------------------------------------

Die üblichen CSS-Farben (siehe den Befehl [DefineColor](../commands-de/definecolor.html)) sind schon vordefiniert, allerdings im RGB-Farbraum, der sich vom Prinzip her nur für die Bildschirmdarstellung eignet. So ist folgende Ausgabe ohne vorherige Farbdefinition gültig:

    <PlaceObject>
      <Box width="5" height="2" backgroundcolor="goldenrod" />
    </PlaceObject>


Direkte Nutzung von CSS-RGB-Werten
------------------------------------

Alternativ zu den vordefinierten Namen kann im speedata Publisher auch die RGB-Hexwerte direkt angeben:

    <PlaceObject>
      <Box width="5" height="2" backgroundcolor="#DAA520" />
    </PlaceObject>

Indirekte Farbdefinition
-------------------------

Die indirekte Farbdefiniton wurde oben schon gezeigt. Sie eignet sich insbesondere dann, wenn man einer Farbe einen symbolischen Namen zuordnen möchte.

    <DefineColor name="hintergrund" model="cmyk" c="97" m="77" y="0" k="3"/>
    <DefineColor name="vordergrund" model="cmyk" c="2" m="12" y="59" k="1"/>


Farbräume
---------

Es gibt verschiedene Farbräume, in denen Farben definiert werden können. Für
die Bildschirmausgabe ist der Farbraum »RGB« üblich. Dieser Farbraum eignet
sich nicht für die Druckausgabe, da hier die Farben auf normalerweise einen
weißen Untergrund aufgetragen werden und die Farben subtraktiv gemischt
werden. Hier wird üblicherweise der Farbraum »CMYK« benutzt. Zwar kann man
rechnerisch RGB in CMYK umwandeln, in der Praxis funktioniert das nur
eingeschränkt. In der Druckausgabe ebenfalls üblich sind Graustufen und
Schmuck- oder Sonderfarben (Z.B. HKS oder Pantone).



Sonderfarben / Schmuckfarben
----------------------------

Im Gegensatz zu den Farben aus dem RGB-Farbraum kann man im speedata Publisher Sonderfarben nur indirekt benutzen. Hier gibt es nämlich die Problematik, dass die Sonderfarben nur gedruckt werden, aber nicht am Bildschirm angezeigt werden können. Man muss für jede Sonderfarbe eine Ersatzfarbe angeben, die der Sonderfarbe möglichst nahe kommt. Diese wird verwendet, wenn die Sonderfarbe nicht zur Verfügung steht.

Für die gängigen Pantone-Sonderfarben hat der speedata Publisher die Ersatzdefinitionen vordefiniert. So ist die folgende Defintion ausreichend

    <DefineColor name="hintergrund" model="spotcolor" colorname="PANTONE 115 C" />

um die Farbe »Pantone 115 C« im Drucker anzusteuern und auf dem Bildschirm auszugeben.

Eigene Farben muss man hingegen wie folgt definieren:

    <DefineColor name="hintergrund" model="spotcolor" colorname="Lack" c="12" m="8" y="20" k="0"  />


Überdrucken
-----------

Bei indirekt definierten Farben kann man die Eigenschaft »überdrucken«
einstellen. Das ist eine Anweisung an den Rastergrafikprozessor (RIP), die
unterliegenden Farben beim Druck nicht auszusparen, sondern zusätzlich zu
drucken. Dazu muss in der Farbdefinition »overprint="yes"« gesetzt werden.
Das Ergebnis kann man mit den einschlägigen Preflight-Tools, wie z.B. Acrobat Professional, überprüfen.


