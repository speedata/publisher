---
title: "Arrays und Maps"
weight: 162
type: docs
---

Der speedata Publisher unterstützt Arrays und Maps als native Datenstrukturen.
Damit lassen sich geordnete Listen und Schlüssel-Wert-Zuordnungen direkt in XPath-Ausdrücken verwenden – ohne den Umweg über dynamisch erzeugte Variablennamen.

Die Konstruktoren (`[...]`, `array { ... }`, `map { ... }`) und der Lookup-Operator (`?`) sind direkt verwendbar.
Für die Funktionen wie `array:size()`, `map:keys()` usw. müssen die entsprechenden Namensräume im Wurzelelement deklariert werden:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map">
```

Die Präfixe `array` und `map` sind frei wählbar, die Namensraum-URIs müssen aber genau so angegeben werden.

## Arrays

Ein Array ist eine geordnete Folge von Werten. Jedes Element (»Member«) kann ein beliebiger XPath-Wert sein - Zahlen, Zeichenketten oder sogar weitere Arrays und Maps.

### Array erzeugen

Eckige Klammern - jeder Ausdruck wird zu einem Member:

```xml
<SetVariable variable="farben" select="['rot', 'grün', 'blau']"/>
<SetVariable variable="zahlen" select="[10, 20, 30]"/>
<SetVariable variable="leer" select="[]"/>
```

Curly-Konstruktor - eine Sequenz wird in einzelne Members aufgeteilt:

```xml
<SetVariable variable="eins_bis_fünf" select="array { 1 to 5 }"/>
```

Das Ergebnis ist ein Array mit fünf Members: 1, 2, 3, 4, 5.

### Auf Array-Elemente zugreifen

Der Lookup-Operator `?` greift per Index (1-basiert) auf ein Member zu:

```xml
<Value select="$farben?1"/>   <!-- ergibt: rot -->
<Value select="$farben?3"/>   <!-- ergibt: blau -->
```

Mit dem Wildcard `?*` erhält man alle Members als flache Sequenz:

```xml
<Value select="string-join($farben?*, ', ')"/>
<!-- ergibt: rot, grün, blau -->
```

### Array-Funktionen

Alle Array-Funktionen befinden sich im Namensraum `array:`. Arrays sind unveränderlich – Funktionen wie `array:put()` oder `array:append()` geben ein neues Array zurück, das Original bleibt unverändert.

`array:size(<Array>)`
: Anzahl der Members. `array:size([1, 2, 3])` ergibt `3`.

`array:get(<Array>, <Position>)`
: Gibt das Member an der Position zurück. `array:get(['a', 'b', 'c'], 2)` ergibt `b`.

`array:append(<Array>, <Wert>)`
: Neues Array mit angehängtem Member. `array:append([1, 2], 3)` ergibt `[1, 2, 3]`.

`array:put(<Array>, <Position>, <Wert>)`
: Neues Array mit ersetztem Member an der Position.

`array:remove(<Array>, <Position>)`
: Neues Array ohne das Member an der Position.

`array:subarray(<Array>, <Start>[, <Länge>])`
: Teilarray ab der Startposition.

`array:join(<Array-Sequenz>)`
: Verbindet eine Sequenz von Arrays zu einem einzigen Array.

`array:flatten(<Array>)`
: Löst verschachtelte Arrays rekursiv auf und gibt eine flache Sequenz zurück. `array:flatten([1, [2, 3]])` ergibt die Sequenz `1, 2, 3`.

## Maps

Eine Map ist eine Sammlung von Schlüssel-Wert-Paaren. Schlüssel sind atomare Werte (typischerweise Zeichenketten oder Zahlen), Werte können beliebig sein.

### Map erzeugen

```xml
<SetVariable variable="preise"
    select="map { 'Apfel': 1.50, 'Birne': 2.30, 'Kirsche': 4.90 }"/>
<SetVariable variable="leer" select="map {}"/>
```

Schlüssel und Wert werden durch `:` getrennt, Einträge durch `,`.

### Auf Map-Einträge zugreifen

Der Lookup-Operator `?` greift per Schlüsselname zu:

```xml
<Value select="$preise?Apfel"/>   <!-- ergibt: 1.5 -->
<Value select="$preise?Kirsche"/> <!-- ergibt: 4.9 -->
```

Mit dem Wildcard `?*` erhält man alle Werte:

```xml
<Value select="count($preise?*)"/>  <!-- ergibt: 3 -->
```

### Map-Funktionen

Alle Map-Funktionen befinden sich im Namensraum `map:` und geben neue Maps zurück.

`map:size(<Map>)`
: Anzahl der Einträge. `map:size(map { 'a': 1, 'b': 2 })` ergibt `2`.

`map:keys(<Map>)`
: Gibt die Schlüssel als Sequenz zurück.

`map:get(<Map>, <Schlüssel>)`
: Gibt den Wert zum Schlüssel zurück. Leere Sequenz, wenn der Schlüssel nicht existiert.

`map:contains(<Map>, <Schlüssel>)`
: `true()` wenn der Schlüssel vorhanden ist.

`map:put(<Map>, <Schlüssel>, <Wert>)`
: Neue Map mit eingefügtem oder ersetztem Eintrag.

`map:remove(<Map>, <Schlüssel>)`
: Neue Map ohne den Eintrag.

`map:merge(<Map-Sequenz>)`
: Führt eine Sequenz von Maps zusammen. Bei doppelten Schlüsseln gewinnt der letzte Wert.

`map:entry(<Schlüssel>, <Wert>)`
: Erzeugt eine Map mit einem einzigen Eintrag.


## Praxisbeispiele

### Produktkatalog mit Preisen

```xml
<SetVariable variable="preise" select="map {
    'SKU-001': 29.95,
    'SKU-002': 79.00,
    'SKU-003': 149.90
}"/>

<Record element="product">
    <PlaceObject>
        <Textblock>
            <Paragraph>
                <Value select="@name || ': ' || $preise?(@sku) || ' €'"/>
            </Paragraph>
        </Textblock>
    </PlaceObject>
</Record>
```

### Farbzuordnung

```xml
<SetVariable variable="farben" select="map {
    'fehler': 'rot',
    'warnung': 'gelb',
    'ok': 'grün'
}"/>

<Value select="$farben?($status)"/>
```

### Sammlung aufbauen

Da Arrays und Maps unveränderlich sind, baut man Sammlungen schrittweise auf:

```xml
<SetVariable variable="einträge" select="[]"/>

<SetVariable variable="einträge"
    select="array:append($einträge, 'Erster Eintrag')"/>
<SetVariable variable="einträge"
    select="array:append($einträge, 'Zweiter Eintrag')"/>
```
