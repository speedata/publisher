package main

import (
	"context"
	"crypto/md5"
	"encoding/xml"
	"fmt"
	"io"
	"log/slog"
	"os"
	"strings"
	"time"
)

const (
	// LevelMessage is used for messages from Message
	LevelMessage = slog.Level(3)
)

var (
	lvl          = new(slog.LevelVar)
	enc          *xml.Encoder
	msgAttr      = xml.Attr{Name: xml.Name{Local: "msg"}}
	lvlAttr      = xml.Attr{Name: xml.Name{Local: "level"}}
	logElement   = xml.StartElement{Name: xml.Name{Local: "entry"}}
	protocolFile io.Writer
	errCount     = 0
	warnCount    = 0
	loglevel     slog.LevelVar
	repl         = strings.NewReplacer(" ", "-") // for XML attribute names
	startElement xml.StartElement
)

type logHandler struct {
}

func (lh *logHandler) Enabled(_ context.Context, level slog.Level) bool {
	if level == slog.LevelError {
		errCount++
	} else if level == slog.LevelWarn {
		warnCount++
	}
	return level >= loglevel.Level()
}

func (lh *logHandler) Handle(_ context.Context, r slog.Record) error {
	lvlAttr.Value = r.Level.String()
	if r.Level == LevelMessage {
		lvlAttr.Value = "MESSAGE"
	} else if r.Level == -8 {
		lvlAttr.Value = "TRACE"
	}
	msgAttr.Value = r.Message
	values := []string{}
	le := logElement.Copy()
	le.Attr = append(le.Attr, lvlAttr, msgAttr)
	r.Attrs(
		func(a slog.Attr) bool {
			var val string
			switch t := a.Value.Any().(type) {
			case slog.LogValuer:
				val = t.LogValue().String()
				values = append(values, fmt.Sprintf("%s=%s", a.Key, val))
			default:
				t = a.Value
				val = a.Value.String()
				values = append(values, fmt.Sprintf("%s=%s", a.Key, a.Value))
			}
			le.Attr = append(le.Attr, xml.Attr{Name: xml.Name{Local: repl.Replace(a.Key)}, Value: val})
			return true
		})
	enc.EncodeToken(xml.CharData([]byte("  ")))
	enc.EncodeToken(le)
	enc.EncodeToken(le.End())
	enc.EncodeToken(xml.CharData([]byte("\n")))

	if verbosity > 0 {
		lparen := ""
		rparen := ""
		if len(values) > 0 {
			lparen = "("
			rparen = ")"
		}
		lvlString := "·  "
		switch r.Level {
		case slog.LevelWarn:
			lvlString = "W: "
		case slog.LevelError:
			lvlString = "E: "
		}
		fmt.Println(lvlString, r.Message, lparen+strings.Join(values, ",")+rparen)
	}
	return nil
}

func (lh *logHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
	return lh
}

func (lh *logHandler) WithGroup(name string) slog.Handler {
	return lh
}

// protocol is the name of the XML protocol file
func setupLog(protocol string) error {
	var err error

	switch os.Getenv("SD_LOGLEVEL") {
	case "trace":
		loglevel.Set(slog.Level(-8))
	case "debug":
		loglevel.Set(slog.LevelDebug)
	case "info":
		loglevel.Set(slog.LevelInfo)
	case "message":
		loglevel.Set(LevelMessage)
	case "warn":
		loglevel.Set(slog.LevelWarn)
	case "error":
		loglevel.Set(slog.LevelError)
	}

	protocolFile, err = os.Create(protocol)
	if err != nil {
		return err
	}
	sl := slog.New(&logHandler{})
	slog.SetDefault(sl)

	enc = xml.NewEncoder(protocolFile)
	startElement = xml.StartElement{
		Name: xml.Name{Local: "log"},
		Attr: []xml.Attr{
			{Name: xml.Name{Local: "loglevel"}, Value: loglevel.Level().String()},
			{Name: xml.Name{Local: "time"}, Value: time.Now().Format(time.Stamp)},
			{Name: xml.Name{Local: "version"}, Value: os.Getenv("PUBLISHERVERSION")},
			{Name: xml.Name{Local: "pro"}, Value: os.Getenv("SP_PRO")},
		},
	}
	if err = enc.EncodeToken(startElement); err != nil {
		return err
	}
	enc.EncodeToken(xml.CharData([]byte("\n")))

	return nil
}

func teardownLog() error {
	if err := enc.EncodeToken(startElement.End()); err != nil {
		return err
	}
	if err := enc.Flush(); err != nil {
		return err
	}
	return nil
}

// see the section on performance considerations in the slog package for a
// rationale why I chose this way to do the calculation.
type md5calc string

func (e md5calc) LogValue() slog.Value {
	data, err := os.ReadFile(string(e))
	if err != nil {
		return slog.StringValue(err.Error())
	}
	return slog.AnyValue(fmt.Sprintf("%x", md5.Sum(data)))
}
