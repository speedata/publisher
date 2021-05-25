package css

import (
	"os"
	"path/filepath"
	"strings"

	"github.com/PuerkitoBio/goquery"
)

func (c *CSS) openHTMLFile(filename string) error {
	dir, fn := filepath.Split(filename)
	c.dirstack = append(c.dirstack, dir)
	dirs := strings.Join(c.dirstack, "")
	r, err := os.Open(filepath.Join(dirs, fn))
	if err != nil {
		return err
	}
	c.document, err = goquery.NewDocumentFromReader(r)
	if err != nil {
		return err
	}
	var errcond error
	c.document.Find(":root > head link").Each(func(i int, sel *goquery.Selection) {
		if stylesheetfile, attExists := sel.Attr("href"); attExists {
			block, err := c.parseCSSFile(stylesheetfile)
			if err != nil {
				errcond = err
			}
			parsedStyles := consumeBlock(block, false)
			c.Stylesheet = append(c.Stylesheet, parsedStyles)
		}
	})
	return errcond
}
