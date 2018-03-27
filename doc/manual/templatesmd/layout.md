{{define "filelist"}}
{{if .IsEn}}List of files{{else}}Dateiliste{{end}}
=============

{{ if $.IsEn}}File{{else}}Datei{{ end}} | {{ if $.IsEn}}Description{{else}}Beschreibung{{ end}}
-----|------------
{{ range $index, $entry :=  filelist . }}<a href="{{$entry.Link}}">{{$entry.Filename}}</a>| {{$entry.Description}}
{{end}}

{{ with thumbnail . }}
{{ if $.IsEn}}Preview{{else}}Vorschau{{ end}}
-----------------

<img src="{{.}}" style="border: 1pt solid black;">
{{ end}}

<a href="{{ parentdir .}}">{{if .IsEn}}Parent directory{{else}}Übergeordnetes Verzeichnis{{end}}</a>

{{end}}

{{define "changelog"}}
<!-- disable markdown: -->
<div>
{{ range .Changelog.Chapter }}<h2>Version {{ .Version }} {{ with .Date}}({{.}}){{end}}</h2>
<ul>{{range .Entries }}<li>{{if $.IsEn}}{{.En.Text}}{{else}}{{.De.Text}}{{end}} ({{.Version}})</li>{{end}}
</ul>{{end}}
</div>
{{ end }}