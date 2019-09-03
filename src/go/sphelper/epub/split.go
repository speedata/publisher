package epub

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"

	"github.com/alecthomas/chroma"
	"github.com/alecthomas/chroma/formatters/html"
	"github.com/alecthomas/chroma/lexers"
	"github.com/alecthomas/chroma/styles"
)

type titleSubtitles struct {
	sectionname string
	subsections []string
}

var (
	chapternumber int
	idfilemapping = make(map[string]string)
	idNameMapping = make(map[string]string)
	filenameTitle = make(map[string]titleSubtitles)

	headerlevel = 0
	coReplace   *regexp.Regexp
	enc         *xml.Encoder
	fileEnc     *xml.Encoder
	extension   = "xhtml"
	removeTags  *strings.Replacer
)

func init() {
	coReplace = regexp.MustCompile(`CO\d+-(\d+)`)
	removeTags = strings.NewReplacer("<kbd>", "", "</kbd>", "")
}

const (
	VARIABLELIST = iota
	ITEMIZEDLIST
	CALLOUTLIST
	ORDEREDLIST
)

func getIds(r io.ReadSeeker) error {
	defer func() { chapternumber = 0 }()
	dec := xml.NewDecoder(r)
	var id string
	var chardata string
	var saveChardata bool
	var filename string
gatherid:
	for {
		tok, err := dec.Token()
		if err == io.EOF {
			break gatherid
		}
		if err != nil {
			break gatherid
		}

		switch elt := tok.(type) {
		case xml.StartElement:
			switch elt.Name.Local {
			case "preface", "chapter", "appendix":
				id = attr(elt, "id")
				headerlevel += 1
				filename = getFilename()
				if err != nil {
					return err
				}
				if id != "" {
					idfilemapping[id] = filename
				}
			case "anchor", "section", "figure", "formalpara":
				id = attr(elt, "id")
				idfilemapping[id] = filename
			case "title":
				saveChardata = true
			}
		case xml.CharData:
			if saveChardata {
				chardata = string(elt.Copy())
			}
		case xml.EndElement:
			switch elt.Name.Local {
			case "preface", "chapter", "appendix":
				headerlevel -= 1
			case "title":
				saveChardata = true
				idNameMapping[id] = chardata
			}

		}
	}

	n, err := r.Seek(0, io.SeekStart)
	if n != 0 {
		return fmt.Errorf("cannot seek to position 0")
	}
	if err != nil {
		return err
	}
	return nil
}
func getFilename() string {
	fn := fmt.Sprintf("chap-%03d.%s", chapternumber, extension)
	chapternumber++
	return fn
}

func newEncoder(outdir string) (io.WriteCloser, string, error) {
	fn := fmt.Sprintf("chap-%03d.%s", chapternumber, extension)
	chapternumber++
	w, err := os.OpenFile(filepath.Join(outdir, fn), os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0644)
	if err != nil {
		return nil, "", err
	}
	enc = xml.NewEncoder(w)
	fileEnc = enc
	return w, fn, nil
}

func writeString(s string, w io.Writer) {
	enc.Flush()
	w.Write([]byte(s))
	// enc.EncodeToken(xml.CharData(s))
}

func newline() {
	enc.EncodeToken(xml.CharData("\n"))
}

func divStart(classnameAndAttributes ...string) {
	div := xml.StartElement{Name: xml.Name{Local: "div"}}
	if len(classnameAndAttributes) > 0 {
		div.Attr = append(div.Attr, xml.Attr{Name: xml.Name{Local: "class"}, Value: classnameAndAttributes[0]})
	}
	classnameAndAttributes = classnameAndAttributes[1:]
	for {
		if len(classnameAndAttributes) > 1 {
			div.Attr = append(div.Attr, xml.Attr{Name: xml.Name{Local: classnameAndAttributes[0]}, Value: classnameAndAttributes[1]})
			classnameAndAttributes = classnameAndAttributes[2:]
		} else {
			break
		}
	}
	newline()
	enc.EncodeToken(div)
}

func divEnd() {
	enc.EncodeToken(xml.EndElement{Name: xml.Name{Local: "div"}})
	newline()
}

func elementStart(elt xml.StartElement) {
	enc.EncodeToken(elt)
}

func elementEnd(elt xml.StartElement) {
	enc.EncodeToken(elt.End())
}

func attr(s xml.StartElement, attrname string) string {
	for _, attr := range s.Attr {
		if attr.Name.Local == attrname {
			return attr.Value
		}
	}
	return ""
}

func setAttr(s *xml.StartElement, attname, value string) {
	s.Attr = append(s.Attr, xml.Attr{Name: xml.Name{Local: attname}, Value: value})
}

func newBytesEncoder(b *bytes.Buffer) *xml.Encoder {
	b.Reset()
	be := xml.NewEncoder(b)
	return be
}

func secondPass(r io.Reader, outdir string) error {
	var wc io.WriteCloser
	var b bytes.Buffer

	writeHead := false
	var chardata string
	var saveid string
	var title string

	var dynhead xml.StartElement
	var a = xml.StartElement{Name: xml.Name{Local: "a"}}
	var p = xml.StartElement{Name: xml.Name{Local: "p"}}
	var blockquote = xml.StartElement{Name: xml.Name{Local: "blockquote"}}
	var calloutlist = xml.StartElement{Name: xml.Name{Local: "ol"}, Attr: []xml.Attr{{Name: xml.Name{Local: "class"}, Value: "calloutlist"}}}
	var emphasis = xml.StartElement{Name: xml.Name{Local: "em"}}
	var entry = xml.StartElement{Name: xml.Name{Local: "td"}}
	var informaltable = xml.StartElement{Name: xml.Name{Local: "table"}}
	var row = xml.StartElement{Name: xml.Name{Local: "tr"}}
	var imagedata = xml.StartElement{Name: xml.Name{Local: "img"}}
	var literal = xml.StartElement{Name: xml.Name{Local: "kbd"}}
	var listitem = xml.StartElement{Name: xml.Name{Local: "li"}}
	var itemize = xml.StartElement{Name: xml.Name{Local: "ul"}}
	var orderedlist = xml.StartElement{Name: xml.Name{Local: "ol"}, Attr: []xml.Attr{{Name: xml.Name{Local: "class"}, Value: "orderedlist"}}}
	var programlisting = xml.StartElement{Name: xml.Name{Local: "pre"}, Attr: []xml.Attr{{Name: xml.Name{Local: "class"}, Value: "chroma"}}}
	var subscript = xml.StartElement{Name: xml.Name{Local: "sub"}}
	var varlistitem = xml.StartElement{Name: xml.Name{Local: "dd"}}
	var varlistterm = xml.StartElement{Name: xml.Name{Local: "dt"}}
	var variablelist = xml.StartElement{Name: xml.Name{Local: "dl"}}
	var thead = xml.StartElement{Name: xml.Name{Local: "thead"}}
	var tbody = xml.StartElement{Name: xml.Name{Local: "tbody"}}

	var bridgeheadlevel int

	var writeCharData bool

	var inLiteral bool
	var inFigure bool
	var inFormalPara bool
	var omitPara bool

	var filename string
	var programListingLang string
	var subsections []string

	repl := strings.NewReplacer("&lt;", "<", "&gt;", ">", "&#34;", `"`, "&#39;", `'`, "&amp;", "&", "&#x9;", "    ")
	listtype := []int{}
	dec := xml.NewDecoder(r)

	for {
		tok, err := dec.Token()
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}

		switch elt := tok.(type) {
		case xml.StartElement:
			switch elt.Name.Local {
			case "informalfigure", "mediaobject", "imageobject", "book":
			case "textobject":
				dec.Skip()
			case "info":
				err = dec.Skip()
				if err != nil {
					return err
				}
			case "preface", "chapter", "appendix":
				saveid = attr(elt, "id")
				headerlevel += 1
				title = ""
				wc, filename, err = newEncoder(outdir)
				if err != nil {
					return err
				}
				if writeHead {
					enc.EncodeToken(xml.StartElement{Name: xml.Name{Local: "html", Space: "http://www.w3.org/1999/xhtml"}})
					enc.EncodeToken(xml.StartElement{Name: xml.Name{Local: "head"}})
					enc.EncodeToken(xml.EndElement{Name: xml.Name{Local: "head"}})
					enc.EncodeToken(xml.StartElement{Name: xml.Name{Local: "body"}})
				}
				subsections = []string{}
			case "anchor":
				anchor := a.Copy()
				id := attr(elt, "id")
				idfilemapping[id] = filename
				setAttr(&anchor, "id", id)
			case "attribution":
				enc = newBytesEncoder(&b)
				writeCharData = true
			case "blockquote":
				divStart("quoteblock")
				enc.EncodeToken(blockquote)
			case "bridgehead":
				switch attr(elt, "renderas") {
				case "sect2":
					bridgeheadlevel = 2
				case "sect3", "sect4":
					bridgeheadlevel = 3
				}
				saveid = attr(elt, "id")
				enc = newBytesEncoder(&b)
				writeCharData = true
				// saveCharData = true
			case "calloutlist":
				enc.EncodeToken(calloutlist)
				listtype = append(listtype, CALLOUTLIST)
			case "co":
				for _, attr := range elt.Attr {
					switch attr.Name.Local {
					case "id":
						conumRaw := coReplace.ReplaceAllString(attr.Value, "$1")
						conum, err := strconv.Atoi(conumRaw)
						if err != nil {
							return err
						}
						enc.EncodeToken(xml.CharData(string('①' + conum - 1)))
					}
				}
			case "emphasis":
				enc.EncodeToken(emphasis)
			case "entry":
				writeCharData = true
				omitPara = true
				elementStart(entry)
			case "figure":
				inFigure = true
				attributes := []string{"imageblock"}
				idatt := attr(elt, "id")
				if idatt != "" {
					attributes = append(attributes, []string{"id", idatt}...)
				}
				divStart(attributes...)
				divStart("content")
			case "formalpara":
				inFormalPara = true
				inFigure = true
				attributes := []string{"imageblock"}
				idatt := attr(elt, "id")
				if idatt != "" {
					attributes = append(attributes, []string{"id", idatt}...)
				}
				divStart(attributes...)
				divStart("content")
			case "itemizedlist":
				listtype = append(listtype, ITEMIZEDLIST)
				enc.EncodeToken(itemize)
			case "imagedata":
				img := imagedata.Copy()
				// wd := attr(elt, "width")
				// cwd := attr(elt, "contentwidth")
				// switch {
				// case wd != "":
				// 	setAttr(&img, "width", wd)
				// case cwd != "":
				// 	setAttr(&img, "width", cwd)
				// }
				setAttr(&img, "src", strings.Replace(attr(elt, "fileref"), "img/", "../images/", 1))
				enc.EncodeToken(img)
				enc.EncodeToken(img.End())
			case "indexterm":
				dec.Skip()
			case "informaltable":
				elementStart(informaltable)
			case "link":
				if !inLiteral {
					e := a.Copy()
					for _, attr := range elt.Attr {
						switch attr.Name.Local {
						case "href":
							e.Attr = append(e.Attr, xml.Attr{Name: xml.Name{Local: "href"}, Value: attr.Value})
						case "linkend":
							id := attr.Value
							fn := idfilemapping[id]
							e.Attr = append(e.Attr, xml.Attr{Name: xml.Name{Local: "href"}, Value: fn + "#" + id})
						}
					}
					enc.EncodeToken(e)
				}
			case "literal":
				enc.EncodeToken(literal)
				inLiteral = true
			case "listitem", "callout":
				if listtype[len(listtype)-1] == VARIABLELIST {
					enc.EncodeToken(varlistitem)
				} else {
					enc.EncodeToken(listitem)
					omitPara = true
					writeCharData = true
				}
			case "orderedlist":
				listtype = append(listtype, ORDEREDLIST)
				enc.EncodeToken(orderedlist)
			case "programlisting", "screen":
				newline()
				enc.EncodeToken(programlisting)
				programListingLang = attr(elt, "language")
				enc = newBytesEncoder(&b)
				writeCharData = true
			case "row":
				elementStart(row)
			case "tbody":
				elementStart(tbody)
			case "tgroup", "colspec":
				// ignore
			case "thead":
				elementStart(thead)
			case "tip", "warning":
				divStart(elt.Name.Local)
			case "title":
				if inFigure || inFormalPara {
					// saveCharData = true
				} else {
					newline()
					dynhead = xml.StartElement{Name: xml.Name{Local: fmt.Sprintf("h%d", headerlevel)}}
					setAttr(&dynhead, "id", saveid)
					enc.EncodeToken(dynhead)
				}
				enc = newBytesEncoder(&b)
				writeCharData = true
			case "section":
				saveid = attr(elt, "id")
				headerlevel += 1
			case "simpara", "para":
				if !inFormalPara && !omitPara {
					enc.EncodeToken(p)
					writeCharData = true
				}
			case "subscript":
				enc.EncodeToken(subscript)
			case "term":
				enc.EncodeToken(varlistterm)
				writeCharData = true
			case "variablelist":
				enc.EncodeToken(variablelist)
				listtype = append(listtype, VARIABLELIST)
			case "varlistentry":
			case "xref":
				anchor := a.Copy()
				for _, attr := range elt.Attr {
					switch attr.Name.Local {
					case "linkend":
						if fn, ok := idfilemapping[attr.Value]; !ok {
							fmt.Println("mapping", attr.Value, "nicht gefunden")
						} else {
							setAttr(&anchor, "href", fn+"#"+attr.Value)
						}
						enc.EncodeToken(anchor)
						if destname, ok := idNameMapping[attr.Value]; !ok {

							enc.EncodeToken(xml.CharData("??? xref ???"))
						} else {
							enc.EncodeToken(xml.CharData(destname))

						}
						enc.EncodeToken(anchor.End())
					}
				}
			default:
				fmt.Println("unknown element", elt.Name.Local)
			}
		case xml.CharData:
			switch {
			case writeCharData:
				enc.EncodeToken(elt.Copy())
				// 	fallthrough
				// case saveCharData:
				// 	chardata = string(elt.Copy())
			}
		case xml.EndElement:
			switch elt.Name.Local {
			case "preface", "chapter", "appendix":
				t := filenameTitle[filename]
				t.subsections = subsections
				filenameTitle[filename] = t
				headerlevel -= 1
				if writeHead {
					enc.EncodeToken(xml.EndElement{Name: xml.Name{Local: "body"}})
					enc.EncodeToken(xml.EndElement{Name: xml.Name{Local: "html", Space: "http://www.w3.org/1999/xhtml"}})
				}
				enc.Flush()
				wc.Close()
			case "section":
				headerlevel -= 1
				newline()
			case "attribution":
				writeCharData = false
				enc.Flush()
				enc = fileEnc
				chardata = b.String()
			case "blockquote":
				enc.EncodeToken(blockquote.End())
				divStart("attribution")
				enc.EncodeToken(xml.CharData("–  " + chardata))
				divEnd()
				divEnd()
			case "bridgehead":
				head := xml.StartElement{Name: xml.Name{Local: fmt.Sprintf("h%d", bridgeheadlevel)}}
				setAttr(&head, "id", saveid)
				writeCharData = false
				enc.Flush()
				enc = fileEnc
				x := b.String()
				enc.EncodeToken(head)
				enc.EncodeToken(x)
				enc.EncodeToken(head.End())
				newline()
			case "calloutlist":
				enc.EncodeToken(calloutlist.End())
				if listtype[len(listtype)-1] != CALLOUTLIST {
					panic("calloutlist not closed")
				}
				listtype = listtype[:len(listtype)-1]
			case "emphasis":
				enc.EncodeToken(emphasis.End())
			case "entry":
				omitPara = false
				writeCharData = false
				elementEnd(entry)
			case "figure":
				inFigure = false
				divEnd()
				divStart("caption")
				writeString(chardata, wc)
				divEnd()
				divEnd()
			case "formalpara":
				inFigure = false
				inFormalPara = false
				divEnd()
				divStart("caption")
				writeString(title, wc)
				divEnd()
				divEnd()
			case "informaltable":
				elementEnd(informaltable)
			case "itemizedlist":
				if listtype[len(listtype)-1] != ITEMIZEDLIST {
					panic("itemizedlist not closed")
				}
				listtype = listtype[:len(listtype)-1]
				enc.EncodeToken(itemize.End())
				newline()
			case "link":
				if !inLiteral {
					enc.EncodeToken(a.End())
				}
			case "literal":
				enc.EncodeToken(literal.End())
				inLiteral = false
			case "orderedlist":
				if listtype[len(listtype)-1] != ORDEREDLIST {
					panic("orderedlist not closed")
				}

				listtype = listtype[:len(listtype)-1]
				enc.EncodeToken(orderedlist.End())
				newline()
			case "programlisting", "screen":
				enc.Flush()
				enc = fileEnc

				style := styles.Get("borland")
				if style == nil {
					style = styles.Fallback
				}
				formatter := html.New(html.PreventSurroundingPre(), html.WithClasses())

				var lexer chroma.Lexer
				switch programListingLang {
				case "sh", "shell":
					lexer = lexers.Get("bash")
				case "xml":
					lexer = lexers.Get("xml")
				case "json":
					lexer = lexers.Get("json")
				case "lua":
					lexer = lexers.Get("lua")
				default:
					lexer = lexers.Fallback
				}

				source := repl.Replace(b.String())
				iterator, err := lexer.Tokenise(nil, source)
				if err != nil {
					return err
				}

				var str strings.Builder
				err = formatter.Format(&str, style, iterator)
				writeString(str.String(), wc)
				enc.EncodeToken(programlisting.End())
				enc.EncodeToken(xml.CharData("\n\n"))
				writeCharData = false
			case "row":
				elementEnd(row)
			case "simpara", "para":
				if !inFormalPara && !omitPara {
					if err = enc.EncodeToken(p.End()); err != nil {
						return err
					}
					newline()
					writeCharData = false
				}
			case "subscript":
				enc.EncodeToken(subscript.End())
			case "listitem", "callout":
				if listtype[len(listtype)-1] == VARIABLELIST {
					enc.EncodeToken(varlistitem.End())
				} else {
					enc.EncodeToken(listitem.End())
					writeCharData = false
					omitPara = false
				}
				newline()
			case "tip", "warning":
				divEnd()
			case "term":
				enc.EncodeToken(varlistterm.End())
				writeCharData = false
			case "tbody":
				elementEnd(tbody)
			case "thead":
				elementEnd(thead)
			case "title":
				enc.Flush()
				enc = fileEnc
				chardata = b.String()
				writeCharData = false
				if title == "" {
					filenameTitle[filename] = titleSubtitles{sectionname: chardata}
				}
				title = chardata
				if headerlevel == 2 && !inFigure {
					subsections = append(subsections, removeTag(title))
					subsections = append(subsections, saveid)
				}
				if !inFigure {
					writeString(title, wc)
					enc.EncodeToken(dynhead.End())
					newline()
				}
			case "variablelist":
				if listtype[len(listtype)-1] != VARIABLELIST {
					panic("variablelist not closed")
				}
				enc.EncodeToken(variablelist.End())
				listtype = listtype[:len(listtype)-1]
			case "varlistentry":
			}
		}
	}
}

func removeTag(title string) string {
	return removeTags.Replace(title)
}

func splitDocBookChapters(r io.ReadSeeker, outdir string, conf *ebpubconf) error {
	err := getIds(r)
	if err != nil {
		return err
	}

	err = secondPass(r, outdir)
	if err != nil {
		return err
	}

	keys := make([]string, 0, len(filenameTitle))
	for k := range filenameTitle {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	for _, k := range keys {
		section := []string{k, filenameTitle[k].sectionname}
		section = append(section, filenameTitle[k].subsections...)
		conf.Sections = append(conf.Sections, section)
	}
	return nil
}
