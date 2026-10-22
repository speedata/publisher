---
title: "Hyphenation / language settings"
weight: 43
type: docs
aliases:
  - /en/basics/hyphenation-language/
---



Hyphenation is necessary in most Western languages to have an acceptable appearance for narrow texts. Hyphenation is an integral part of the line breaking algorithm, for example to avoid multiple hyphenations in consecutive lines.

Hyphenation is controlled by language in the Publisher and is pattern-based. The language can be set globally via `<Options mainlanguage="...">` or paragraphwise.

```xml
<Options mainlanguage="German" />
```

switches the entire document to German hyphenation patterns, while

```xml
<Paragraph language="German">
    <Value>Autobahn</Value>
</Paragraph>
```

changes the language for only one paragraph. The available languages are described in the command reference under [`<Options>`]({{< relref "/reference/commands/options" >}}).

Alternatively to the written out names like `German`, the language code can be used.
The two examples above can also be used as follows:

```xml
<Options mainlanguage="de" />

<Paragraph language="de">
    <Value>Autobahn</Value>
</Paragraph>
```

If you want to test if the words are hyphenated correctly, you can create small marks with `<Trace hyphenation="yes" />`. All switches of the `<Trace>` command are listed in the chapter [Troubleshooting / Debugging]({{< relref "troubleshooting" >}}).

```xml
<Layout
  xmlns="urn:speedata.de:2009/publisher/en"
  xmlns:sd="urn:speedata:2009/publisher/functions/en">

  <Options mainlanguage="German" />
  <Trace hyphenation="yes" />

  <Record element="data">
    <PlaceObject>
      <Textblock width="3">
        <Paragraph>
          <Value>Autobahn</Value>
        </Paragraph>
      </Textblock>
    </PlaceObject>
  </Record>
</Layout>
```

results in the following:

![Show hyphenation points in text](/img/13-autobahn.png)

Via

```xml
<Hyphenation>er-go-no-mic</Hyphenation>
```

you can define hyphenation suggestions or exceptions for individual words. In this way, the words are then only hyphenated at the positions indicated by a hyphen. The `language` attribute can be used to specify the language for which the separation exception applies.

{{< callout >}}
With optical margin alignment, which is described in the section [marginprotrusion]({{< relref "textformatting" >}}), you can reduce the number of hyphenations in the document somewhat.
{{< /callout >}}

## Turn off paragraph hyphenations

For single paragraphs you can switch off the automatic hyphenation by defining a text format with `hyphenate="no"`.

```xml
<DefineTextformat name="nohyphen" hyphenate="no"/>
```

No words are hyphenated in paragraphs marked in this way. The use of text formats is described [in a separate section]({{< relref "textformat" >}}).

The hyphenation character can also be changed using a text format:

```xml
<DefineTextformat name="dothyphen" hyphenchar="•"/>
```

![Other character for word hyphenations](/img/13-dothyphen.png)

## Use different languages within a paragraph

You can set the language for a textblock, a paragraph and you can even set the language for a piece of text by surrounding the text by `<Span language="...">` and `</Span>`.

```xml
<Paragraph language="en">
  <Span language="de">
    <Value>Also schön, Guido Heffels,
           nachfolgend meine Textempfehlung
           für das Blindtextbuch.
    </Value>
  </Span>
  <Br />
  <Span>
    <Value>A wonderful serenity has taken
           possession of my entire soul, like these sweet
           mornings of spring which I enjoy with my whole
           heart.
    </Value>
  </Span>
</Paragraph>
```

## Allow hyphenations only on certain characters

A property of `<Paragraph>` allows to limit the characters where a line break may be inserted. This is often important for technical data where, for example, type designations in the form `12-345/AB` occur and should not be hyphenated. In the following example, a line break may only be inserted after a slash:

```xml
<Paragraph allowbreak="/">
  <Value>https://download.speedata.de/publisher/development/</Value>
</Paragraph>
```

The default setting for allowbreak is “ -”, i.e. a break at a space or hyphen.

{{< callout >}}
This is an experimental feature in the Publisher. It is likely to be associated with a text format in a future version.
{{< /callout >}}

## Controlling line breaks with special characters

Some Unicode characters control line breaking directly in the text.
They are invisible and can be written as numeric character references in the data or in the layout.

| Character | Input | Effect |
|---|---|---|
| U+00AD soft hyphen | `&#xAD;` | The word may be hyphenated at this position. At the end of the line the hyphen character of the text format (`hyphenchar`) appears, otherwise the character stays invisible. |
| U+200B zero width space | `&#x200B;` | A line break without a hyphen is allowed, for example in long product names or in Thai (see [Writing systems]({{< relref "scripts" >}})). |
| U+2060 word joiner | `&#x2060;` | No line break between the two characters. |
| U+00A0 no-break space | `&#xA0;` | A space where the line is not broken, for example between a number and its unit. |

```xml
<Paragraph>
  <Value>Donau&#xAD;dampf&#xAD;schiff&#xAD;fahrt, 12&#xA0;kg</Value>
</Paragraph>
```

A line break after a hyphen cannot be prevented with U+2060, use the attribute `allowbreak` for that (see above).

## Other writing systems

Right-to-left scripts such as Arabic and Hebrew, Chinese, Japanese and Korean, and Thai and related scripts have their own rules for the writing direction, line breaking and the forms of the characters.
They are described in the section [Writing systems]({{< relref "scripts" >}}).
