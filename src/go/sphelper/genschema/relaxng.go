package genschema

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"strings"
)

const (
	// RELAXNG is the Relax NG Namespace
	RELAXNG string = "http://relaxng.org/ns/structure/1.0"
	// LSPNAMESPACE is the namespace for xml-lsp schema annotations
	LSPNAMESPACE string = "urn:xml-lsp:annotations"
)

var (
	refElement      xml.StartElement
	emptyElement    xml.StartElement
	valueElement    xml.StartElement
	optionalElement xml.StartElement
	choiceElement   xml.StartElement
)

func init() {
	refElement = xml.StartElement{Name: xml.Name{Local: "ref"}}
	emptyElement = xml.StartElement{Name: xml.Name{Local: "empty"}}
	valueElement = xml.StartElement{Name: xml.Name{Local: "value"}}
	optionalElement = xml.StartElement{Name: xml.Name{Local: "optional"}}
	choiceElement = xml.StartElement{Name: xml.Name{Local: "choice"}}
}

// lspElement returns an empty start element in the lsp namespace with the
// given attributes. Attributes with an empty value are omitted.
func lspElement(name string, attrs ...xml.Attr) xml.StartElement {
	elt := xml.StartElement{Name: xml.Name{Local: "lsp:" + name}}
	for _, a := range attrs {
		if a.Value != "" {
			elt.Attr = append(elt.Attr, a)
		}
	}
	return elt
}

func xmlAttr(name, value string) xml.Attr {
	return xml.Attr{Name: xml.Name{Local: name}, Value: value}
}

func encodeEmpty(enc *xml.Encoder, elt xml.StartElement) {
	enc.EncodeToken(elt)
	enc.EncodeToken(elt.End())
}

// yesToTrue maps the commands.xml boolean "yes" to the "true" used in the
// lsp annotations. Any other value yields an empty string, which drops the
// attribute in lspElement.
func yesToTrue(v string) string {
	if v == "yes" {
		return "true"
	}
	return ""
}

// writeLspGrammarAnnotations writes the annotations that belong to the
// grammar as a whole: namespace prefixes for xmlns completion and the
// built-in symbol names. They are written directly after the grammar start,
// before the start element.
func writeLspGrammarAnnotations(commands *commandsXML, enc *xml.Encoder) {
	for _, ns := range commands.LspAnnotations.Namespaces {
		encodeEmpty(enc, lspElement("namespace", xmlAttr("prefix", ns.Prefix), xmlAttr("uri", ns.URI)))
	}
	for _, b := range commands.LspAnnotations.Builtins {
		encodeEmpty(enc, lspElement("builtin", xmlAttr("symbol", b.Symbol), xmlAttr("names", strings.Join(strings.Fields(b.Names), " "))))
	}
}

// writeLspElementAnnotations writes the annotations of a command directly
// after its a:documentation element: the link to the manual, formatter
// hints, the document symbol, exclusive attributes and conditional
// attributes.
func writeLspElementAnnotations(commands *commandsXML, enc *xml.Encoder, cmdname, lang string) {
	encodeEmpty(enc, lspElement("doc", xmlAttr("href", lspDocURL(cmdname, lang))))
	if f := commands.lspFormatAnnotation(cmdname); f != nil {
		encodeEmpty(enc, lspElement("format", xmlAttr("preserve", yesToTrue(f.Preserve)), xmlAttr("blank-lines", yesToTrue(f.BlankLines)), xmlAttr("inline", yesToTrue(f.Inline))))
	}
	if s := commands.lspDocSymbolAnnotation(cmdname); s != nil {
		encodeEmpty(enc, lspElement("symbol", xmlAttr("kind", s.Kind), xmlAttr("label", s.Label), xmlAttr("detail", s.Detail)))
	}
	for _, e := range commands.lspExclusiveAnnotations(cmdname) {
		encodeEmpty(enc, lspElement("exclusive", xmlAttr("attributes", e.Attributes), xmlAttr("content", yesToTrue(e.Content))))
	}
	for _, w := range commands.lspWhenAnnotations(cmdname) {
		// A rule with several values expands to one annotation per value. A
		// rule without a value applies when the attribute is absent.
		values := strings.Fields(w.Value)
		if len(values) == 0 {
			values = []string{""}
		}
		for _, v := range values {
			encodeEmpty(enc, lspElement("when", xmlAttr("attribute", w.Attribute), xmlAttr("value", v), xmlAttr("requires", w.Requires), xmlAttr("forbids", w.Forbids)))
		}
	}
}

// writeLspAttributeAnnotation writes the defines/references annotation of an
// attribute directly after its a:documentation element.
func writeLspAttributeAnnotation(commands *commandsXML, enc *xml.Encoder, cmdname, attname string) {
	if kind, symbol, form := commands.lspSymbolAnnotation(cmdname, attname); kind != "" {
		encodeEmpty(enc, lspElement(kind, xmlAttr("symbol", symbol), xmlAttr("form", form)))
	}
}

// writeChildElements writes the child elements from this command to the encoder.
func writeChildElements(commands *commandsXML, enc *xml.Encoder, children []byte, lang string) {
	if len(children) == 0 {
		enc.EncodeToken(emptyElement.Copy())
		enc.EncodeToken(emptyElement.End())
		return
	}
	buf := bytes.NewBuffer(children)
	dec := xml.NewDecoder(buf)
	for {
		tok, err := dec.Token()
		if err != nil {
			return
		}
		switch v := tok.(type) {
		case xml.StartElement:
			switch v.Name.Local {
			case "cmd":
				ref := refElement.Copy()
				for _, attr := range v.Attr {
					if attr.Name.Local == "name" {
						ref.Attr = []xml.Attr{{Name: xml.Name{Local: "name"}, Value: "e_" + attr.Value}}
					}
				}
				enc.EncodeToken(ref)
			case "description":
			case "choice":
				enc.EncodeToken(choiceElement.Copy())
				for _, attribute := range v.Attr {
					if attribute.Name.Local == lang {
						enc.EncodeToken(valueElement.Copy())
						enc.EncodeToken(xml.CharData(attribute.Value))
						enc.EncodeToken(valueElement.End())
					}
				}
			case "reference":
				for _, attr := range v.Attr {
					if attr.Name.Local == "name" {
						if attr.Value == "html" || attr.Value == "mathml" {
							// These references point to static defines in the
							// schema (see the literal block at the end of
							// genRelaxNGSchema), not to a define in commands.xml.
							se := xml.StartElement{Name: xml.Name{Local: "ref"}}
							se.Attr = append(se.Attr, xml.Attr{Name: xml.Name{Local: "name"}, Value: attr.Value})
							enc.EncodeToken(se)
							enc.EncodeToken(se.End())
						} else {
							writeChildElements(commands, enc, commands.getDefine(attr.Value), lang)
						}
					}
				}
			default:
				enc.EncodeToken(v.Copy())
			}

		case xml.EndElement:
			switch v.Name.Local {
			case "cmd":
				enc.EncodeToken(refElement.End())
			case "choice":
				enc.EncodeToken(choiceElement.End())
			default:
				enc.EncodeToken(v)
			}
		}
	}
}

func genRelaxNGSchema(commands *commandsXML, lang string, allowForeignNodes bool) ([]byte, error) {
	var outbuf bytes.Buffer
	var interleave, group xml.StartElement

	enc := xml.NewEncoder(&outbuf)
	enc.Indent("", "   ")

	grammar := xml.StartElement{Name: xml.Name{Local: "grammar", Space: RELAXNG}}
	grammar.Attr = []xml.Attr{
		{Name: xml.Name{Local: "xmlns:a"}, Value: "http://relaxng.org/ns/compatibility/annotations/1.0"},
		{Name: xml.Name{Local: "xmlns:sch"}, Value: "http://purl.oclc.org/dsdl/schematron"},
		{Name: xml.Name{Local: "ns"}, Value: SDNAMESPACE},
		{Name: xml.Name{Local: "datatypeLibrary"}, Value: "http://www.w3.org/2001/XMLSchema-datatypes"},
	}
	// The lsp annotations (see doc/commands-xml/commands.xml, section
	// lspannotations) are only written in the second pass. The first pass is
	// converted to XSD by trang and should stay free of foreign elements.
	if allowForeignNodes {
		grammar.Attr = append(grammar.Attr, xml.Attr{Name: xml.Name{Local: "xmlns:lsp"}, Value: LSPNAMESPACE})
	}

	enc.EncodeToken(xml.Comment("Do not edit this file. Auto generated from commands.xml with sphelper."))
	enc.EncodeToken(xml.CharData("\n"))
	enc.EncodeToken(grammar)
	sch := xml.StartElement{Name: xml.Name{Local: "sch:ns"}}
	sch.Attr = []xml.Attr{
		{Name: xml.Name{Local: "prefix"}, Value: "t"},
		{Name: xml.Name{Local: "uri"}, Value: SDNAMESPACE},
	}
	enc.EncodeToken(sch)
	enc.EncodeToken(sch.End())

	if allowForeignNodes {
		writeLspGrammarAnnotations(commands, enc)
	}

	start := xml.StartElement{Name: xml.Name{Local: "start"}}
	enc.EncodeToken(start)

	choice := xml.StartElement{Name: xml.Name{Local: "choice"}}
	enc.EncodeToken(choice)

	refLayout := xml.StartElement{Name: xml.Name{Local: "ref"}}
	refLayout.Attr = []xml.Attr{{Name: xml.Name{Local: "name"}, Value: "e_Layout"}}
	refInclude := xml.StartElement{Name: xml.Name{Local: "ref"}}
	refInclude.Attr = []xml.Attr{{Name: xml.Name{Local: "name"}, Value: "e_Include"}}

	enc.EncodeToken(refLayout)
	enc.EncodeToken(refLayout.End())
	enc.EncodeToken(refInclude)
	enc.EncodeToken(refInclude.End())
	enc.EncodeToken(choice.End())
	enc.EncodeToken(start.End())

	attributeElement := xml.StartElement{Name: xml.Name{Local: "attribute"}}

	for _, cmd := range commands.Commands {
		enc.Flush()
		for _, r := range cmd.Rules {
			if r.Lang == lang {
				outbuf.WriteString(r.Rules)
			}
		}
		def := xml.StartElement{Name: xml.Name{Local: "define"}}
		def.Attr = []xml.Attr{{Name: xml.Name{Local: "name"}, Value: "e_" + cmd.Name}}
		enc.EncodeToken(def)

		elt := xml.StartElement{Name: xml.Name{Local: "element"}}
		elt.Attr = []xml.Attr{{Name: xml.Name{Local: "name"}, Value: cmd.Name}}
		enc.EncodeToken(elt)

		doc := xml.StartElement{Name: xml.Name{Local: "a:documentation"}}
		enc.EncodeToken(doc)
		enc.EncodeToken(xml.CharData(cmd.getCommandDescription(lang)))
		enc.EncodeToken(doc.End())

		if allowForeignNodes {
			writeLspElementAnnotations(commands, enc, cmd.Name, lang)
		}

		// if the child elements contents is "empty", there is no need for allowing foreign nodes (1/2)
		if cmd.Name != "Include" && len(cmd.Childelements.Text) > 0 {
			interleave = xml.StartElement{Name: xml.Name{Local: "interleave"}}
			enc.EncodeToken(interleave)

			group = xml.StartElement{Name: xml.Name{Local: "group"}}
			enc.EncodeToken(group)
		}

		for _, attr := range cmd.Attributes {
			if attr.Optional == "yes" {
				enc.EncodeToken(optionalElement.Copy())
			}

			attelt := attributeElement.Copy()
			attelt.Attr = []xml.Attr{{Name: xml.Name{Local: "name"}, Value: attr.Name}}
			enc.EncodeToken(attelt)

			doc := xml.StartElement{Name: xml.Name{Local: "a:documentation"}}
			enc.EncodeToken(doc)
			enc.EncodeToken(xml.CharData(attr.GetDescription(lang)))
			enc.EncodeToken(doc.End())

			if allowForeignNodes {
				writeLspAttributeAnnotation(commands, enc, cmd.Name, attr.Name)
			}

			if len(attr.Choice) > 0 {
				enc.EncodeToken(choiceElement.Copy())
				for _, choice := range attr.Choice {
					enc.EncodeToken(valueElement.Copy())
					enc.EncodeToken(xml.CharData(choice.Name))
					enc.EncodeToken(valueElement.End())

					doc := xml.StartElement{Name: xml.Name{Local: "a:documentation"}}
					enc.EncodeToken(doc)
					enc.EncodeToken(xml.CharData(choice.GetDescription(lang)))
					enc.EncodeToken(doc.End())

				}
				if attr.AllowXPath == "yes" {
					data := xml.StartElement{Name: xml.Name{Local: "data"}}
					data.Attr = []xml.Attr{{Name: xml.Name{Local: "type"}, Value: "string"}}
					enc.EncodeToken(data)
					param := xml.StartElement{Name: xml.Name{Local: "param"}}
					param.Attr = []xml.Attr{{Name: xml.Name{Local: "name"}, Value: "pattern"}}
					enc.EncodeToken(param)
					enc.EncodeToken(xml.CharData(`\{.+\}`))
					enc.EncodeToken(param.End())
					enc.EncodeToken(data.End())
				}

				enc.EncodeToken(choiceElement.End())
			} else if attr.Type == "yesnonumber" {
				data := xml.StartElement{Name: xml.Name{Local: "data"}}
				data.Attr = []xml.Attr{{Name: xml.Name{Local: "type"}, Value: "string"}}
				enc.EncodeToken(data)
				param := xml.StartElement{Name: xml.Name{Local: "param"}}
				param.Attr = []xml.Attr{{Name: xml.Name{Local: "name"}, Value: "pattern"}}
				enc.EncodeToken(param)
				enc.EncodeToken(xml.CharData(`[0-9]+|yes|no`))
				enc.EncodeToken(param.End())
				enc.EncodeToken(data.End())
			} else if attr.Type == "boolean" {
				enc.EncodeToken(choiceElement.Copy())
				enc.EncodeToken(valueElement.Copy())
				enc.EncodeToken(xml.CharData("yes"))
				enc.EncodeToken(valueElement.End())
				enc.EncodeToken(valueElement.Copy())
				enc.EncodeToken(xml.CharData("no"))
				enc.EncodeToken(valueElement.End())
				if attr.AllowXPath == "yes" {
					data := xml.StartElement{Name: xml.Name{Local: "data"}}
					data.Attr = []xml.Attr{{Name: xml.Name{Local: "type"}, Value: "string"}}
					enc.EncodeToken(data)
					param := xml.StartElement{Name: xml.Name{Local: "param"}}
					param.Attr = []xml.Attr{{Name: xml.Name{Local: "name"}, Value: "pattern"}}
					enc.EncodeToken(param)
					enc.EncodeToken(xml.CharData(`\{.+\}`))
					enc.EncodeToken(param.End())
					enc.EncodeToken(data.End())
				}
				enc.EncodeToken(choiceElement.End())
			}

			if attr.Reference.Name != "" {
				d := commands.DefineAttrs
				for _, attrdefinition := range d {
					if attr.Reference.Name == attrdefinition.Name {
						enc.EncodeToken(choiceElement.Copy())
						if attr.AllowXPath == "yes" {
							data := xml.StartElement{Name: xml.Name{Local: "data"}}
							data.Attr = []xml.Attr{{Name: xml.Name{Local: "type"}, Value: "string"}}
							enc.EncodeToken(data)
							param := xml.StartElement{Name: xml.Name{Local: "param"}}
							param.Attr = []xml.Attr{{Name: xml.Name{Local: "name"}, Value: "pattern"}}
							enc.EncodeToken(param)
							enc.EncodeToken(xml.CharData(`\{.+\}`))
							enc.EncodeToken(param.End())
							enc.EncodeToken(data.End())
						}
						if attrdefinition.Name == "languages" {
							dl := commands.DefineList
							for _, deflist := range dl {
								if deflist.Name == "languagesshortcodes" {
									data := xml.StartElement{Name: xml.Name{Local: "data"}}
									data.Attr = []xml.Attr{{Name: xml.Name{Local: "type"}, Value: "string"}}
									enc.EncodeToken(data)
									param := xml.StartElement{Name: xml.Name{Local: "param"}}
									param.Attr = []xml.Attr{{Name: xml.Name{Local: "name"}, Value: "pattern"}}
									enc.EncodeToken(param)
									enc.EncodeToken(xml.CharData(string(deflist.Text)))
									enc.EncodeToken(param.End())
									enc.EncodeToken(data.End())
								}
							}
						}
						for _, choice := range attrdefinition.Choices {
							enc.EncodeToken(valueElement.Copy())
							enc.EncodeToken(xml.CharData(choice.Name))
							enc.EncodeToken(valueElement.End())

							doc := xml.StartElement{Name: xml.Name{Local: "a:documentation"}}
							enc.EncodeToken(doc)
							enc.EncodeToken(xml.CharData(choice.GetDescription(lang)))
							enc.EncodeToken(doc.End())

						}
						enc.EncodeToken(choiceElement.End())
					}
				}
			}
			enc.EncodeToken(attelt.End())
			if attr.Optional == "yes" {
				enc.EncodeToken(optionalElement.Copy().End())
			}
		}
		writeChildElements(commands, enc, cmd.Childelements.Text, lang)

		// if the child elements contents is "empty", there is no need for allowing foreign nodes (2/2)
		if cmd.Name != "Include" && len(cmd.Childelements.Text) > 0 {
			enc.EncodeToken(group.End())
			if allowForeignNodes {
				ref := xml.StartElement{Name: xml.Name{Local: "ref"}}
				ref.Attr = []xml.Attr{{Name: xml.Name{Local: "name"}, Value: "foreign-nodes"}}
				enc.EncodeToken(ref)
				enc.EncodeToken(ref.End())
			}
			enc.EncodeToken(interleave.End())
		}
		enc.EncodeToken(elt.End())
		enc.EncodeToken(def.End())
	}
	enc.Flush()
	fmt.Fprint(&outbuf, `
	<!-- allow HTML in <Value> ... </Value> -->
    <define name="htmlclassidstyle">
        <optional><attribute name="class"/></optional>
        <optional><attribute name="id"/></optional>
        <optional><attribute name="style"/></optional>
    </define>
	<define name="html">
		<zeroOrMore>
		    <choice>
			    <element name="a"><attribute name="href"/><ref name="html"/></element>
				<element name="br"><empty /></element>
				<element name="h1"><ref name="htmlclassidstyle"/><ref name="html" /></element>
				<element name="h2"><ref name="htmlclassidstyle"/><ref name="html" /></element>
				<element name="h3"><ref name="htmlclassidstyle"/><ref name="html" /></element>
				<element name="h4"><ref name="htmlclassidstyle"/><ref name="html" /></element>
				<element name="h5"><ref name="htmlclassidstyle"/><ref name="html" /></element>
				<element name="b"><ref name="htmlclassidstyle"/><ref name="html" /></element>
			    <element name="code"><ref name="htmlclassidstyle"/><ref name="html" /></element>
			    <element name="i"><ref name="htmlclassidstyle"/><ref name="html" /></element>
			    <element name="kbd"><ref name="htmlclassidstyle"/><ref name="html" /></element>
			    <element name="li"><ref name="htmlclassidstyle"/><ref name="html" /></element>
			    <element name="p"><ref name="htmlclassidstyle"/><ref name="html" /></element>
			    <element name="span"><ref name="htmlclassidstyle"/><ref name="html" /></element>
                <element name="table"><ref name="htmlclassidstyle"/><ref name="htmltable" /></element>
			    <element name="u"><ref name="htmlclassidstyle"/><ref name="html" /></element>
			    <element name="ul"><ref name="htmlclassidstyle"/><ref name="html" /></element>
			    <element name="ol"><ref name="htmlclassidstyle"/><ref name="html" /></element>
			    <element name="body"><ref name="htmlclassidstyle"/><ref name="html" /></element>
			    <text></text>
		    </choice>
		</zeroOrMore>
	</define>
    <define name="htmltable">
        <zeroOrMore>
            <ref name="colgroup"/>
        </zeroOrMore>
        <optional>
            <element name="thead">
                <ref name="htmlclassidstyle" />
                <oneOrMore>
                    <ref name="tr"/>
                </oneOrMore>
            </element>
        </optional>
        <choice>
            <optional>
                <element name="tbody">
                    <ref name="htmlclassidstyle" />
                    <oneOrMore>
                        <ref name="tr"/>
                    </oneOrMore>
                </element>
            </optional>
            <oneOrMore>
                <ref name="tr"/>
            </oneOrMore>
        </choice>
    </define>
    <define name="colgroup">
        <element name="colgroup">
            <oneOrMore>
                <element name="col">
                    <attribute name="width"/>
                    <empty />
                </element>
            </oneOrMore>
        </element>
    </define>
    <define name="tr">
        <element name="tr">
            <ref name="htmlclassidstyle"/>
            <oneOrMore>
                <choice>
                    <element name="td">
                        <ref name="htmlclassidstyle"></ref>
                        <ref name="html"/>
                    </element>
                    <element name="th">
                        <ref name="htmlclassidstyle"></ref>
                        <ref name="html"/>
                    </element>
                </choice>
            </oneOrMore>
        </element>
    </define>
	<!-- MathML subset in <Math> ... </Math>. The elements inherit the
	     layout namespace, so the MathML namespace is not required. -->
	<define name="mathml">
        <zeroOrMore>
            <ref name="mathml-element"/>
        </zeroOrMore>
    </define>
    <define name="mathml-element">
        <choice>
            <element name="math"><ref name="mathml"/></element>
            <element name="mrow"><ref name="mathml"/></element>
            <element name="msqrt"><ref name="mathml"/></element>
            <element name="mstyle">
                <optional><attribute name="displaystyle"/></optional>
                <optional><attribute name="scriptlevel"/></optional>
                <ref name="mathml"/>
            </element>
            <element name="mi">
                <optional><attribute name="mathvariant"/></optional>
                <text/>
            </element>
            <element name="mn"><text/></element>
            <element name="mo">
                <optional><attribute name="stretchy"/></optional>
                <text/>
            </element>
            <element name="mtext"><text/></element>
            <element name="mspace">
                <optional><attribute name="width"/></optional>
            </element>
            <element name="mfrac">
                <optional><attribute name="linethickness"/></optional>
                <ref name="mathml-element"/>
                <ref name="mathml-element"/>
            </element>
            <element name="mroot">
                <ref name="mathml-element"/>
                <ref name="mathml-element"/>
            </element>
            <element name="msup">
                <ref name="mathml-element"/>
                <ref name="mathml-element"/>
            </element>
            <element name="msub">
                <ref name="mathml-element"/>
                <ref name="mathml-element"/>
            </element>
            <element name="msubsup">
                <ref name="mathml-element"/>
                <ref name="mathml-element"/>
                <ref name="mathml-element"/>
            </element>
            <element name="munder">
                <optional><attribute name="accentunder"/></optional>
                <ref name="mathml-element"/>
                <ref name="mathml-element"/>
            </element>
            <element name="mover">
                <optional><attribute name="accent"/></optional>
                <ref name="mathml-element"/>
                <ref name="mathml-element"/>
            </element>
            <element name="munderover">
                <optional><attribute name="accent"/></optional>
                <optional><attribute name="accentunder"/></optional>
                <ref name="mathml-element"/>
                <ref name="mathml-element"/>
                <ref name="mathml-element"/>
            </element>
        </choice>
    </define>
`)
	if allowForeignNodes {
		// See feature request #144
		fmt.Fprintln(&outbuf, `
	<!-- This pattern allows any element from any namespace -->
	<define name="anything">
      <zeroOrMore>
         <choice>
            <element>
               <anyName/>
               <ref name="anything"/>
            </element>
            <attribute>
               <anyName/>
            </attribute>
            <text/>
         </choice>
      </zeroOrMore>
   </define>
   <define name="foreign-elements">
      <zeroOrMore>
         <element>
            <anyName>
               <except>
                  <nsName ns=""/>
                  <nsName ns="urn:speedata.de:2009/publisher/en"/>
                  <nsName ns="urn:speedata:2009/publisher/functions/en"/>
               </except>
            </anyName>
            <ref name="anything"/>
         </element>
      </zeroOrMore>
   </define>
   <define name="foreign-attributes">
      <zeroOrMore>
         <attribute>
            <anyName>
               <except>
                  <nsName ns=""/>
                  <nsName ns="urn:speedata.de:2009/publisher/en"/>
                  <nsName ns="urn:speedata:2009/publisher/functions/en"/>
               </except>
            </anyName>
         </attribute>
      </zeroOrMore>
   </define>
   <define name="foreign-nodes">
      <zeroOrMore>
         <choice>
            <ref name="foreign-attributes"/>
            <ref name="foreign-elements"/>
         </choice>
      </zeroOrMore>
   </define>`)
	}

	enc.EncodeToken(grammar.End())
	enc.EncodeToken(xml.CharData("\n"))
	enc.Flush()
	return outbuf.Bytes(), nil
}
