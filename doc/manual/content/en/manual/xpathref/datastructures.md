---
title: "Arrays and Maps"
weight: 162
type: docs
---

The speedata Publisher supports arrays and maps as native data structures.
This allows ordered lists and key-value mappings to be used directly in XPath expressions — without the detour of dynamically generated variable names.

The constructors (`[...]`, `array { ... }`, `map { ... }`) and the lookup operator (`?`) can be used directly.
To use functions like `array:size()`, `map:keys()` etc., the corresponding namespaces must be declared in the root element:

```xml
<Layout xmlns="urn:speedata.de:2009/publisher/en"
    xmlns:sd="urn:speedata:2009/publisher/functions/en"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map">
```

The prefixes `array` and `map` can be chosen freely, but the namespace URIs must be exactly as shown.

## Arrays

An array is an ordered collection of values. Each element ("member") can be any XPath value — numbers, strings, or even other arrays and maps.

### Creating arrays

Square brackets — each expression becomes a member:

```xml
<SetVariable variable="colors" select="['red', 'green', 'blue']"/>
<SetVariable variable="numbers" select="[10, 20, 30]"/>
<SetVariable variable="empty" select="[]"/>
```

Curly constructor — a sequence is split into individual members:

```xml
<SetVariable variable="one_to_five" select="array { 1 to 5 }"/>
```

The result is an array with five members: 1, 2, 3, 4, 5.

### Accessing array elements

The lookup operator `?` accesses a member by index (1-based):

```xml
<Value select="$colors?1"/>   <!-- returns: red -->
<Value select="$colors?3"/>   <!-- returns: blue -->
```

The wildcard `?*` returns all members as a flat sequence:

```xml
<Value select="string-join($colors?*, ', ')"/>
<!-- returns: red, green, blue -->
```

### Array functions

All array functions are in the `array:` namespace. Arrays are immutable – functions like `array:put()` or `array:append()` return a new array, the original remains unchanged.

`array:size(<array>)`
: Number of members. `array:size([1, 2, 3])` returns `3`.

`array:get(<array>, <position>)`
: Return the member at the given position. `array:get(['a', 'b', 'c'], 2)` returns `b`.

`array:append(<array>, <value>)`
: New array with appended member. `array:append([1, 2], 3)` returns `[1, 2, 3]`.

`array:put(<array>, <position>, <value>)`
: New array with replaced member at the given position.

`array:remove(<array>, <position>)`
: New array without the member at the given position.

`array:subarray(<array>, <start>[, <length>])`
: Sub-array starting at the given position.

`array:join(<array-sequence>)`
: Concatenate a sequence of arrays into a single array.

`array:flatten(<array>)`
: Recursively flatten nested arrays into a flat sequence. `array:flatten([1, [2, 3]])` returns the sequence `1, 2, 3`.

## Maps

A map is a collection of key-value pairs. Keys are atomic values (typically strings or numbers), values can be anything.

### Creating maps

```xml
<SetVariable variable="prices"
    select="map { 'apple': 1.50, 'pear': 2.30, 'cherry': 4.90 }"/>
<SetVariable variable="empty" select="map {}"/>
```

Keys and values are separated by `:`, entries by `,`.

### Accessing map entries

The lookup operator `?` accesses entries by key name:

```xml
<Value select="$prices?apple"/>   <!-- returns: 1.5 -->
<Value select="$prices?cherry"/>  <!-- returns: 4.9 -->
```

The wildcard `?*` returns all values:

```xml
<Value select="count($prices?*)"/>  <!-- returns: 3 -->
```

### Map functions

All map functions are in the `map:` namespace and return new maps.

`map:size(<map>)`
: Number of entries. `map:size(map { 'a': 1, 'b': 2 })` returns `2`.

`map:keys(<map>)`
: Return the keys as a sequence.

`map:get(<map>, <key>)`
: Return the value for the key. Empty sequence if the key does not exist.

`map:contains(<map>, <key>)`
: `true()` if the key exists.

`map:put(<map>, <key>, <value>)`
: New map with inserted or replaced entry.

`map:remove(<map>, <key>)`
: New map without the entry.

`map:merge(<map-sequence>)`
: Merge a sequence of maps. For duplicate keys, the last value wins.

`map:entry(<key>, <value>)`
: Create a map with a single entry.


## Practical examples

### Product catalog with prices

```xml
<SetVariable variable="prices" select="map {
    'SKU-001': 29.95,
    'SKU-002': 79.00,
    'SKU-003': 149.90
}"/>

<Record element="product">
    <PlaceObject>
        <Textblock>
            <Paragraph>
                <Value select="@name || ': ' || $prices?(@sku) || ' EUR'"/>
            </Paragraph>
        </Textblock>
    </PlaceObject>
</Record>
```

### Color mapping

```xml
<SetVariable variable="colors" select="map {
    'error': 'red',
    'warning': 'yellow',
    'ok': 'green'
}"/>

<Value select="$colors?($status)"/>
```

### Building a collection

Since arrays and maps are immutable, collections are built incrementally:

```xml
<SetVariable variable="entries" select="[]"/>

<SetVariable variable="entries"
    select="array:append($entries, 'First entry')"/>
<SetVariable variable="entries"
    select="array:append($entries, 'Second entry')"/>
```
