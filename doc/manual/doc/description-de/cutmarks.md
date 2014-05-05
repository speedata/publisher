title: Schnittmarken und Beschnittzugabe
---
Schnittmarken und Beschnittzugabe
=================================

Wird keine gesonderte Einstellung vorgenommen, so erzeugt der speedata
Publisher ein PDF, das genau der Größe der angegebenen Seiten hat. Um
Beschnittzugabe oder Schnittmarken einzuschalten, müssen diese im
Element [Optionen](../commands-de/options.html.html) aktiviert werden:

    <Optionen
       beschnittmarken="ja"
       beschnittzugabe="3mm"
      />

Diese Anweisungen erzeugen Schnittmarken, die eine Länge von 1cm haben
und 3mm vom inneren Seitenrand (TrimBox) entfernt sind. Der Abstand
ergibt sich aus der Beschnittzugabe. Ist die Beschnittzugabe kleiner als
5pt, werden die Schnittmarken mit einem Abstand von 5pt vom Rand
gesetzt.

Die erzeugte PDF-Datei enthält immer die folgenden Boxen: außen ist die
*MediaBox*, die Beschnittzugabe wird durch die *BleedBox* markiert und
die eigentliche Seite durch die *TrimBox*. Wenn keine Beschnittzugabe
angegeben ist, fallen die *BleedBox* und die *TrimBox* aufeinander.
Werden keine Schnittmarken erzeugt, so fällt die *MediaBox* mit der
*TrimBox* zusammen, so dass ohne Angaben von Schnittmarken und
Beschnittzugabe alle drei Boxen dieselben Ausmaße haben.

Beispiel
--------

Im folgenden Beispiel gehen die Schnittmarken bis zur blauen Linie, die
die Beschnittzugabe kennzeichnet. Die grüne Linie zeigt das Endformat
der Seite (Screenshot aus dem Adobe Acrobat).

{{ img . "schnittmarken2.png"  }}

Siehe auch
----------

[Optionen](../commands-de/options.html)
