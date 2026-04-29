// Package luahttp provides a Lua HTTP-client module for use with
// speedata/go-lua. The exposed Lua API mirrors cjoudrey/gluahttp:
// http.get / post / put / delete / head / patch / request, plus a
// response userdata with fields headers, cookies, status_code, url,
// body, body_size. The request_batch helper is intentionally omitted —
// it is rarely used and parallel calls are not safe to share a single
// Lua state.
package luahttp

import (
	"context"
	"io"
	"net/http"
	"strings"
	"time"

	"speedatapublisher/sp/sp/lualib"

	lua "github.com/speedata/go-lua"
)

const responseTypeName = "http.response"

// Module wraps an HTTP client and exposes it as a Lua module.
type Module struct {
	do func(req *http.Request) (*http.Response, error)
}

// New returns a Module that uses the given http.Client.
func New(client *http.Client) *Module {
	return &Module{do: client.Do}
}

type response struct {
	res      *http.Response
	body     string
	bodySize int
}

// Loader registers the Lua module table on the stack and returns 1.
func (m *Module) Loader(l *lua.State) int {
	funcs := []lua.RegistryFunction{
		{Name: "get", Function: m.method("GET")},
		{Name: "delete", Function: m.method("DELETE")},
		{Name: "head", Function: m.method("HEAD")},
		{Name: "patch", Function: m.method("PATCH")},
		{Name: "post", Function: m.method("POST")},
		{Name: "put", Function: m.method("PUT")},
		{Name: "request", Function: m.request},
	}
	lua.NewLibrary(l, funcs)

	lua.NewMetaTable(l, responseTypeName)
	l.PushGoFunction(responseIndex)
	l.SetField(-2, "__index")
	l.SetField(-2, "response")

	return 1
}

func (m *Module) method(method string) lua.Function {
	return func(l *lua.State) int {
		url, _ := l.ToString(1)
		return m.doRequest(l, method, url, 2)
	}
}

func (m *Module) request(l *lua.State) int {
	method, _ := l.ToString(1)
	url, _ := l.ToString(2)
	return m.doRequest(l, strings.ToUpper(method), url, 3)
}

func pushErr(l *lua.State, msg string) int {
	l.PushNil()
	l.PushString(msg)
	return 2
}

func (m *Module) doRequest(l *lua.State, method, url string, optionsIdx int) int {
	req, err := http.NewRequest(method, url, nil)
	if err != nil {
		return pushErr(l, err.Error())
	}

	hasOptions := optionsIdx > 0 && l.Top() >= optionsIdx && l.TypeOf(optionsIdx) == lua.TypeTable

	if hasOptions {
		// cookies
		l.Field(optionsIdx, "cookies")
		if l.IsTable(-1) {
			cIdx := l.AbsIndex(-1)
			l.PushNil()
			for l.Next(cIdx) {
				k, _ := l.ToString(-2)
				v, _ := l.ToString(-1)
				req.AddCookie(&http.Cookie{Name: k, Value: v})
				l.Pop(1)
			}
		}
		l.Pop(1)

		// query string
		if v, ok := lualib.FieldString(l, optionsIdx, "query"); ok {
			req.URL.RawQuery = v
		}

		// body / form
		bodyStr, bodyOk := lualib.FieldString(l, optionsIdx, "body")
		if !bodyOk {
			if v, ok := lualib.FieldString(l, optionsIdx, "form"); ok {
				bodyStr = v
				bodyOk = true
				req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
			}
		}
		if bodyOk {
			req.ContentLength = int64(len(bodyStr))
			req.Body = io.NopCloser(strings.NewReader(bodyStr))
		}

		// timeout
		l.Field(optionsIdx, "timeout")
		var dur time.Duration
		switch l.TypeOf(-1) {
		case lua.TypeNumber:
			secs, _ := l.ToInteger(-1)
			dur = time.Second * time.Duration(secs)
		case lua.TypeString:
			s, _ := l.ToString(-1)
			d, perr := time.ParseDuration(s)
			if perr != nil {
				l.Pop(1)
				return pushErr(l, perr.Error())
			}
			dur = d
		}
		l.Pop(1)
		if dur > 0 {
			ctx, cancel := context.WithTimeout(req.Context(), dur)
			defer cancel()
			req = req.WithContext(ctx)
		}

		// basic auth
		l.Field(optionsIdx, "auth")
		if l.IsTable(-1) {
			aIdx := l.AbsIndex(-1)
			user, uok := lualib.FieldString(l, aIdx, "user")
			pass, pok := lualib.FieldString(l, aIdx, "pass")
			if uok && pok {
				req.SetBasicAuth(user, pass)
			} else {
				l.Pop(1)
				return pushErr(l, "auth table must contain no nil user and pass fields")
			}
		}
		l.Pop(1)

		// headers — set last so the calls above don't overwrite them
		l.Field(optionsIdx, "headers")
		if l.IsTable(-1) {
			hIdx := l.AbsIndex(-1)
			l.PushNil()
			for l.Next(hIdx) {
				k, _ := l.ToString(-2)
				v, _ := l.ToString(-1)
				req.Header.Set(k, v)
				l.Pop(1)
			}
		}
		l.Pop(1)
	}

	res, err := m.do(req)
	if err != nil {
		return pushErr(l, err.Error())
	}
	defer res.Body.Close()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		return pushErr(l, err.Error())
	}

	pushResponse(l, res, string(body), len(body))
	return 1
}

func pushResponse(l *lua.State, res *http.Response, body string, bodySize int) {
	l.PushUserData(&response{res: res, body: body, bodySize: bodySize})
	lua.SetMetaTableNamed(l, responseTypeName)
}

func responseIndex(l *lua.State) int {
	r, ok := lua.CheckUserData(l, 1, responseTypeName).(*response)
	if !ok {
		return 0
	}
	switch lua.CheckString(l, 2) {
	case "headers":
		l.NewTable()
		for k := range r.res.Header {
			l.PushString(r.res.Header.Get(k))
			l.SetField(-2, k)
		}
		return 1
	case "cookies":
		l.NewTable()
		for _, c := range r.res.Cookies() {
			l.PushString(c.Value)
			l.SetField(-2, c.Name)
		}
		return 1
	case "status_code":
		l.PushInteger(r.res.StatusCode)
		return 1
	case "url":
		l.PushString(r.res.Request.URL.String())
		return 1
	case "body":
		l.PushString(r.body)
		return 1
	case "body_size":
		l.PushInteger(r.bodySize)
		return 1
	}
	return 0
}
