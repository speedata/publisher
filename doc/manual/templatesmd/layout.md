{{define "filelist"}}
{{if .IsEn}}List of files{{else}}Dateiliste{{end}}
=============

File | Description
-----|------------
{{ range $index, $entry :=  filelist . }}<a href="{{$entry.Link}}">{{$entry.Filename}}</a>| {{$entry.Description}}
{{end}}

<a href="{{ parentdir .}}">{{if .IsEn}}Parent directory{{else}}Übergeordnetes Verzeichnis{{end}}</a>

{{end}}

{{define "changelog"}}
{{ $isen := .IsEn }}{{ range .Changelog.Chapter }}<h2>Version {{ .Version }}</h2>
<ul>{{range .Entries }}<li>{{if $isen}}{{.En.Text}}{{else}}{{.De.Text}}{{end}} ({{.Version}})</li>{{end}}
</ul>{{end}}
{{ end }}