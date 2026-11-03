---
title: "Icons aus einer Icon-Schrift"
weight: 35
type: docs
---

## Aufgabe

Eine Sortimentsübersicht soll Symbole zeigen: Ein Haus oder eine Sonne kennzeichnet, ob eine Artikelgruppe nur für innen oder auch für außen geeignet ist. Dazu kommen Beschreibungen aus dem Webshop, in die die Redaktion bereits Icons gesetzt hat, und zwar im Markup von Font Awesome (`<i class="fa-solid fa-truck-fast"></i>`). Die Symbole stammen aus einer Icon-Schrift, hier Font Awesome Free.

![Vor jeder Eigenschaftszeile steht ein Haus oder eine Sonne, in den Beschreibungen aus dem Webshop erscheinen ein Lieferwagen, ein Häkchen und ein rotes Warndreieck.](/img/howto-icons.png)

## Entscheidung

Eine Icon-Schrift ist eine gewöhnliche Schriftdatei, deren Zeichen Symbole sind. Die Symbole liegen meist im Unicode-Bereich für private Nutzung (U+E000 bis U+F8FF), das Haus hat in Font Awesome zum Beispiel den Code U+F015. Die Codes stehen in der Symbolübersicht des Anbieters oder im mitgelieferten Stylesheet (`.fa-house::before { content: "\f015" }`).

Wie ein Symbol in den Text kommt, hängt davon ab, wo festgelegt ist, welches Symbol erscheint:

| Wo steht, welches Symbol erscheint? | Weg |
|---|---|
| Das Layout wählt das Symbol anhand der Daten, zum Beispiel nach einem Attribut. | Eine Schriftfamilie mit der Icon-Schrift, im Absatz mit `<Fontface>` |
| Die Daten enthalten HTML mit Klassen, etwa aus einem Webshop oder Redaktionssystem. | Ein Stylesheet mit `::before`-Regeln, wie im Browser |
| Das Zeichen selbst steht in den Daten (`&#xf015;`). | Die Icon-Schrift als Ersatzschrift (`<Fallback>`) der Textschrift |

* **Schriftfamilie mit `<Fontface>`**: Das Layout behält die volle Kontrolle. Die Zuordnung von Datenwert zu Symbol steht in einem XPath-Ausdruck, die Daten bleiben frei von Symbolcodes. Die Schriftfamilie hat eine feste Größe; für Symbole in Überschriften braucht man eine zweite Familie in deren Größe.
* **Stylesheet mit `::before`**: Die Daten bleiben unverändert, die Klassen werden wie im Browser zu Symbolen. Das ist der Weg für Inhalte, die aus Webanwendungen kommen. Das Symbol übernimmt die Größe des umgebenden Textes.
* **Ersatzschrift**: Am Layout ändert sich nur die Schriftdefinition. Jedes Zeichen, das der Textschrift fehlt, wird in der Icon-Schrift gesucht. Das passt, wenn ein vorgelagerter Prozess die Codes bereits in die Daten schreibt. Die Daten enthalten dann allerdings Codes, die nur zusammen mit genau dieser Icon-Schrift einen Sinn ergeben.

Die ersten beiden Wege lassen sich mischen; das Beispiel unten verwendet beide.

## Lösung

### Die Daten

Die Artikelgruppen von Confixa erhalten zwei Angaben: Das Attribut `use` sagt, ob eine Gruppe nur für innen (`indoor`) oder auch für außen (`outdoor`) geeignet ist, und `description` enthält den Beschreibungstext aus dem Webshop, so wie er dort gepflegt wird.

```xml
<data company="Confixa">
  <group name="Spanplattenschrauben" code="CS" material="Stahl, verzinkt" use="indoor">
    <description>Für Spanplatten und Holz. <i class="fa-solid fa-truck-fast"></i> Versand innerhalb von 24 Stunden.</description>
  </group>
  <group name="Dübel" code="WP" material="Nylon" use="outdoor">
    <description>Für Beton, Ziegel und Naturstein. <i class="fa-regular fa-circle-check"></i> Für Fassaden zugelassen.</description>
  </group>
  <group name="Keilanker" code="WA" material="Stahl, verzinkt" use="indoor">
    <description>Für schwere Lasten in Beton. <i class="fa-solid fa-triangle-exclamation"></i> Nur für ungerissenen Beton.</description>
  </group>
</data>
```

### Schritt 1: Die Schriftdateien

Font Awesome Free gibt es auf [fontawesome.com](https://fontawesome.com/download). Das Paket enthält im Verzeichnis `webfonts` unter anderem `fa-solid-900.ttf` (gefüllte Symbole) und `fa-regular-400.ttf` (umrandete Symbole, in der freien Fassung nur eine Auswahl). Die beiden Dateien kommen ins Projektverzeichnis oder in ein Unterverzeichnis davon, dort findet der Publisher sie. Die Schriften stehen unter der SIL Open Font License; ins PDF eingebettet werden dürfen sie ohne Weiteres.

### Schritt 2: Symbole aus dem Layout

Für den ersten Weg wird die Icon-Schrift geladen und als Schriftfamilie definiert, in der Größe des Fließtextes:

```xml
<LoadFontfile name="fa-solid" filename="fa-solid-900.ttf"/>
<DefineFontfamily name="icons" fontsize="10" leading="12">
  <Regular fontface="fa-solid"/>
</DefineFontfamily>
```

Im Absatz schaltet [`<Fontface>`]({{< relref "/reference/commands/fontface" >}}) für das Symbol auf diese Familie um. Welches Symbol erscheint, entscheidet ein XPath-Ausdruck anhand des Attributs `use`:

```xml
<Paragraph>
  <Fontface fontfamily="icons">
    <Value select="if (@use = 'outdoor') then '&#xf185;' else '&#xf015;'"/>
  </Fontface>
  <Value select="if (@use = 'outdoor') then ' Innen und außen' else ' Nur innen'"/>
  <Value select="concat(' · ', @material)"/>
</Paragraph>
```

Die Zeichenreferenzen `&#xf185;` (Sonne) und `&#xf015;` (Haus) löst schon der XML-Parser auf, im XPath-Ausdruck stehen also die Zeichen selbst. Bei vielen verschiedenen Symbolen wird der Ausdruck lang; dann ist eine Zuordnungstabelle in den Daten oder in einer eigenen Datei übersichtlicher.

### Schritt 3: Symbole aus dem Webshop

Für den zweiten Weg wird die Icon-Schrift per `@font-face` im Stylesheet bekannt gemacht, mit beiden Schnitten unter einem Namen. Die Schriftstärke unterscheidet die Schnitte, genau wie im Stylesheet von Font Awesome:

```xml
<Stylesheet>
  @font-face { font-family: "FA"; font-weight: 400; src: url("fa-regular-400.ttf"); }
  @font-face { font-family: "FA"; font-weight: 900; src: url("fa-solid-900.ttf"); }
  .fa-solid, .fa-regular { font-family: "FA"; font-style: normal; }
  .fa-solid { font-weight: 900; }
  .fa-regular { font-weight: 400; }
  .fa-truck-fast::before { content: "\f48b"; }
  .fa-circle-check::before { content: "\f058"; }
  .fa-triangle-exclamation::before { content: "\f071"; color: red; }
</Stylesheet>
```

* Die Klassen `fa-solid` und `fa-regular` wählen Schrift und Schnitt. `font-style: normal` ist nötig, weil `<i>` sonst kursiv setzt und die Icon-Schrift keinen kursiven Schnitt hat.
* Für jedes verwendete Symbol erzeugt eine `::before`-Regel das Zeichen. Weitere Eigenschaften wie die Farbe lassen sich in derselben Regel setzen.

Die Beschreibung wird dann wie jeder andere Text mit Auszeichnungen ausgegeben:

```xml
<Paragraph>
  <Value select="description"/>
</Paragraph>
```

Das Symbol erscheint in der Größe des Absatzes. Steht dieselbe Beschreibung in einer größeren Schrift, wächst das Symbol mit.

Statt eines eigenen Stylesheets lässt sich auch das vollständige Stylesheet von Font Awesome einbinden. Liegen die Verzeichnisse `css` und `webfonts` aus dem Paket im Projektverzeichnis, genügt `<Stylesheet filename="css/all.css"/>`; die Schriftdateien aus den `@font-face`-Regeln findet der Publisher über ihren Namen. Das vollständige Stylesheet ist allerdings rund 140 KB groß und beschreibt über 1800 Symbole. Ein eigenes kurzes Stylesheet mit den tatsächlich verwendeten Symbolen bleibt übersichtlicher und zeigt auf einen Blick, welche Klassen in den Daten vorkommen dürfen.

### Variante: Ersatzschrift

Stehen die Zeichen bereits in den Daten, genügt es, die Textschrift mit der Icon-Schrift als Ersatzschrift erneut zu laden. Für die voreingestellte Schrift TeX Gyre Heros sieht das so aus:

```xml
<LoadFontfile name="TeXGyreHeros-Regular" filename="texgyreheros-regular.otf">
  <Fallback filename="fa-solid-900.ttf"/>
</LoadFontfile>
```

Danach suchen alle Schriftfamilien, die diese Schrift verwenden, fehlende Zeichen in der Icon-Schrift, auch die vordefinierte Familie `text`. Für fetten oder kursiven Text gilt das nur, wenn auch dieser Schnitt (etwa `TeXGyreHeros-Bold`) mit der Ersatzschrift geladen wird. Mehr zu Ersatzschriften steht im Abschnitt [Fehlende Zeichen und Ersatzschriftarten]({{< relref "/manual/text/fonts#fehlende-zeichen-und-ersatzschriftarten" >}}).

### Vollständiges Beispiel

Das lauffähige Projekt gibt es auch im [Beispiel-Repository](https://github.com/speedata/examples/tree/master/manual/icons), dort mit den Schriftdateien und englischen Texten.

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Pageformat width="120mm" height="70mm"/>
  <Margin left="10mm" right="10mm" top="10mm" bottom="10mm"/>

  <DefineFontfamily name="head" fontsize="12" leading="14">
    <Regular fontface="sans-bold"/>
  </DefineFontfamily>
  <DefineTextformat name="grouphead" margin-top="8pt" break-below="no"/>

  <!-- Weg 1: die Icon-Schrift als Schriftfamilie im Layout -->
  <LoadFontfile name="fa-solid" filename="fa-solid-900.ttf"/>
  <DefineFontfamily name="icons" fontsize="10" leading="12">
    <Regular fontface="fa-solid"/>
  </DefineFontfamily>

  <!-- Weg 2: die Icon-Klassen aus dem Webshop -->
  <Stylesheet>
    @font-face { font-family: "FA"; font-weight: 400; src: url("fa-regular-400.ttf"); }
    @font-face { font-family: "FA"; font-weight: 900; src: url("fa-solid-900.ttf"); }
    .fa-solid, .fa-regular { font-family: "FA"; font-style: normal; }
    .fa-solid { font-weight: 900; }
    .fa-regular { font-weight: 400; }
    .fa-truck-fast::before { content: "\f48b"; }
    .fa-circle-check::before { content: "\f058"; }
    .fa-triangle-exclamation::before { content: "\f071"; color: red; }
  </Stylesheet>

  <Record element="data">
    <PlaceObject>
      <Textblock>
        <ForAll select="group">
          <Paragraph fontfamily="head" textformat="grouphead">
            <Value select="@name"/>
          </Paragraph>
          <Paragraph>
            <Fontface fontfamily="icons">
              <Value select="if (@use = 'outdoor') then '&#xf185;' else '&#xf015;'"/>
            </Fontface>
            <Value select="if (@use = 'outdoor') then ' Innen und außen' else ' Nur innen'"/>
            <Value select="concat(' · ', @material)"/>
          </Paragraph>
          <Paragraph>
            <Value select="description"/>
          </Paragraph>
        </ForAll>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

## Grenzen

* **Fehlende Symbole:** Der Regular-Schnitt der freien Fassung enthält nur einen Teil der Symbole. Fehlt ein Symbol, meldet der Publisher wie bei jeder Schrift ein fehlendes Zeichen.
* **Bedeutung im Text:** Im PDF stehen die Symbole als Zeichen aus dem privaten Unicode-Bereich. Beim Kopieren oder beim Vorlesen durch einen Screenreader ergeben sie keinen Sinn. Was ein Symbol aussagt, sollte deshalb auch im Text stehen, wie hier »Nur innen«.
* **Mehrfarbige Symbole:** Icon-Schriften wie Font Awesome haben je Zeichen eine Farbe. Für mehrfarbige Symbole oder Logos sind Bilder im SVG- oder PDF-Format mit [`<Image>`]({{< relref "/reference/commands/image" >}}) der bessere Weg.
