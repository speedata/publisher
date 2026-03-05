package sp

import (
	"bytes"
	"cmp"
	"context"
	"crypto/sha256"
	"fmt"
	"html/template"
	"io"
	"log"
	"math"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"slices"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"

	"github.com/gammazero/workerpool"
)

type compareStatus struct {
	Path           string
	Badpages       []int
	Delta          float64
	CompareNeeded  bool   // true if checksums differ and image comparison ran
	ChecksumEqual  bool   // true if publisher.pdf and reference.pdf have same SHA-256
	PreviewPage    int    // page index for preview (max delta)
	BuildError     bool   // true if running 'sp' failed for this path
	BuildErrorMsg  string // short textual message from 'sp' failure
	StructMismatch int    // 0 = no reference-struct.xml, 1 = match, 2 = mismatch
}

var (
	exeSuffix         string
	cs                []compareStatus
	allPages          []compareStatus
	mutex             *sync.Mutex = &sync.Mutex{}
	wp                *workerpool.WorkerPool
	verbose           bool
	referencefilename string
)

func fileExists(filename string) bool {
	fi, err := os.Stat(filename)
	if err != nil {
		return false
	}
	return !fi.IsDir()
}

var wg sync.WaitGroup

// DoCompare starts comparing the files in the
// current directory and its subdirectory.
// This is the function to be called (first).
// at top-level: add
func DoCompare(absdir string, withHTML bool, moreinfo bool, referencefn string) error {
	switch runtime.GOOS {
	case "windows":
		exeSuffix = ".exe"
	default:
		exeSuffix = ""
	}
	wp = workerpool.New(runtime.NumCPU())
	referencefilename = referencefn
	verbose = moreinfo

	statuschan := make(chan []compareStatus, 64)

	// Start collector and wait for it later
	wg.Add(1)
	go func() {
		getCompareStatus(statuschan)
		wg.Done()
	}()

	compareFunc := mkCompare(statuschan)
	filepath.Walk(absdir, compareFunc)

	// Wait until all submitted comparisons are done
	wp.StopWait()

	// Signal completion to collector by closing the channel
	close(statuschan)

	// Ensure collector finished consuming everything
	wg.Wait()
	if withHTML {
		if err := mkWebPage(!verbose); err != nil {
			return err
		}
	}
	return nil
}

func compareTwoPages(sourcefile, referencefile, dummyfile, path string) float64 {
	sf := filepath.Join(path, sourcefile)
	rf := filepath.Join(path, referencefile)
	if !fileExists(sf) || !fileExists(rf) {
		// Use a sentinel that sorts to top but is recognizable
		return 99.0
	}

	cmd := exec.Command("compare"+exeSuffix, "-metric", "mae", sourcefile, referencefile, dummyfile)
	cmd.Dir = path

	var stderr bytes.Buffer
	cmd.Stdout = io.Discard
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		// Exit 1: metric printed to stderr, differences found.
		if ee, ok := err.(*exec.ExitError); ok {
			if status, ok := ee.Sys().(syscall.WaitStatus); ok && status.ExitStatus() == 1 {
				// stderr typically contains "0.01234"
				s := strings.TrimSpace(stderr.String())
				// Some builds print "0.01234 (X,Y)" -> take first token
				tok := strings.Fields(s)
				if len(tok) > 0 {
					if delta, perr := strconv.ParseFloat(tok[0], 64); perr == nil {
						return delta
					}
				}
				// Fallback if parsing fails
				return 1.0
			}
		}
		// For real errors (exit 2 etc.), return sentinel
		return 99.0
	}
	// Exit 0: identical
	return 0.0
}

func isConversionNeeded(pdf, png string) (bool, error) {
	pngFi, err := os.Stat(png)
	if err != nil {
		// png missing -> need convert
		return true, nil
	}
	pdfFi, err := os.Stat(pdf)
	if err != nil {
		return false, fmt.Errorf("source missing: %s", pdf)
	}
	return pngFi.ModTime().Before(pdfFi.ModTime()), nil
}

// return ([]byte, error) instead of panic
func calculateHash(filename string) ([]byte, error) {
	fh, err := os.Open(filename)
	if err != nil {
		return nil, err
	}
	defer fh.Close()

	h := sha256.New()
	if _, err := io.Copy(h, fh); err != nil {
		return nil, err
	}
	return h.Sum(nil), nil
}

// runComparison: Run convert and compare for one directory
// runComparison builds the test output with `sp`, checksums the PDFs,
// optionally renders PNGs and compares pages, and sends a pair of statuses
// into statuschan: [per-dir status with bad pages, aggregate "all pages" status].
// It never hard-aborts the whole program on per-case errors; instead it logs
// and returns a status entry when possible so the HTML report can surface issues.
func runComparison(path string, statuschan chan []compareStatus) {
	cs := compareStatus{Path: path, PreviewPage: 0}
	all := compareStatus{Path: path, PreviewPage: 0}
	all.Badpages = append(all.Badpages, 0)

	if verbose {
		fmt.Println(path)
	}

	// 1) Run publisher (`sp`) and capture textual output.
	//    If it fails, mark as build error and stop here (no checksum/compare).
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()

	cmd := exec.CommandContext(ctx, "sp"+exeSuffix, "--suppressinfo")
	cmd.Dir = path
	output, err := cmd.CombinedOutput()
	if ctx.Err() == context.DeadlineExceeded {
		cs.BuildError = true
		cs.BuildErrorMsg = "sp timed out"
		all.BuildError, all.BuildErrorMsg = true, cs.BuildErrorMsg
		statuschan <- []compareStatus{cs, all}
		return
	}
	if err != nil {
		cs.BuildError = true
		cs.BuildErrorMsg = strings.TrimSpace(string(output))
		all.BuildError = true
		all.BuildErrorMsg = cs.BuildErrorMsg

		// Keep Delta at 0; report layer will render this as a failed build row.
		statuschan <- []compareStatus{cs, all}
		return
	}

	// 2) Compare checksums of publisher.pdf vs reference.pdf.
	pubPDF := filepath.Join(path, "publisher.pdf")
	refPDF := filepath.Join(path, fmt.Sprintf("%s.pdf", referencefilename))

	// use in runComparison
	p, err := calculateHash(pubPDF)
	if err != nil {
		cs.BuildError = true
		cs.BuildErrorMsg = "hash publisher failed: " + err.Error()
		all.BuildError, all.BuildErrorMsg = true, cs.BuildErrorMsg
		statuschan <- []compareStatus{cs, all}
		return
	}
	r, err := calculateHash(refPDF)
	if err != nil {
		cs.BuildError = true
		cs.BuildErrorMsg = "hash reference failed: " + err.Error()
		all.BuildError, all.BuildErrorMsg = true, cs.BuildErrorMsg
		statuschan <- []compareStatus{cs, all}
		return
	}

	checksumEqual := bytes.Equal(p, r)
	cs.ChecksumEqual = checksumEqual
	all.ChecksumEqual = checksumEqual
	cs.CompareNeeded = !checksumEqual
	all.CompareNeeded = !checksumEqual

	// Compare structure tree XML if reference exists
	refStruct := filepath.Join(path, "reference-struct.xml")
	pubStruct := filepath.Join(path, "publisher-struct.xml")
	if fileExists(refStruct) {
		ph, err1 := calculateHash(pubStruct)
		rh, err2 := calculateHash(refStruct)
		if err1 != nil || err2 != nil {
			cs.StructMismatch = 2
			all.StructMismatch = 2
		} else if bytes.Equal(ph, rh) {
			cs.StructMismatch = 1
			all.StructMismatch = 1
		} else {
			cs.StructMismatch = 2
			all.StructMismatch = 2
		}
	}

	if checksumEqual {
		// No image comparison required; everything matches.
		if verbose {
			fmt.Printf("Files in %q have the same checksum\n", path)
		}
		cs.Delta = 0
		all.Delta = 0
		statuschan <- []compareStatus{cs, all}
		return
	}

	if verbose {
		fmt.Printf("Run convert/compare for %q\n", path)
	}

	// 3) Clean old source PNGs to avoid stale page counts.
	sourceFiles, _ := filepath.Glob(filepath.Join(path, "source-*.png"))
	for _, name := range sourceFiles {
		if err := os.Remove(name); err != nil {
			log.Println(err)
		}
	}

	// 4) Convert publisher.pdf -> source-XX.png
	//    IMPORTANT: Operators like -trim must come AFTER the input.
	cmd = exec.Command("magick"+exeSuffix, "-density", "150", "publisher.pdf", "-trim", "source-%02d.png")
	cmd.Dir = path
	if output, err := cmd.CombinedOutput(); err != nil {
		// Surface convert errors in the report as a "build-like" failure so it's visible.
		cs.BuildError = true
		cs.BuildErrorMsg = "convert publisher failed:\n" + strings.TrimSpace(string(output))
		all.BuildError = true
		all.BuildErrorMsg = cs.BuildErrorMsg
		statuschan <- []compareStatus{cs, all}
		return
	}

	// 5) Convert reference.pdf -> reference-XX.png only if the PDF is newer than PNGs.
	refPng0 := filepath.Join(path, "reference-00.png")
	needRef, err := isConversionNeeded(refPDF, refPng0)
	if err != nil {
		cs.BuildError = true
		cs.BuildErrorMsg = err.Error()
		all.BuildError, all.BuildErrorMsg = true, cs.BuildErrorMsg
		statuschan <- []compareStatus{cs, all}
		return
	}
	if needRef {
		cmd := exec.Command("magick"+exeSuffix, "-density", "150", fmt.Sprintf("%s.pdf", referencefilename), "-trim", referencefilename+"-%02d.png")
		cmd.Dir = path
		if output, err := cmd.CombinedOutput(); err != nil {
			cs.BuildError = true
			cs.BuildErrorMsg = "convert reference failed:\n" + strings.TrimSpace(string(output))
			all.BuildError = true
			all.BuildErrorMsg = cs.BuildErrorMsg
			statuschan <- []compareStatus{cs, all}
			return
		}
	}

	// 6) Enumerate rendered source pages.
	sourceFiles, _ = filepath.Glob(filepath.Join(path, "source-*.png"))
	if len(sourceFiles) == 0 {
		// Should not happen if convert succeeded; report as visible failure.
		cs.BuildError = true
		cs.BuildErrorMsg = "no source PNGs found after convert"
		all.BuildError = true
		all.BuildErrorMsg = cs.BuildErrorMsg
		statuschan <- []compareStatus{cs, all}
		return
	}

	// 7) Compare per page; track maximum delta page as preview.
	maxDeltaPage := 0
	for i := 0; i < len(sourceFiles); i++ {
		sourceFile := fmt.Sprintf("source-%02d.png", i)
		referenceFile := fmt.Sprintf("%s-%02d.png", referencefilename, i)
		dummyFile := fmt.Sprintf("pagediff-%02d.png", i)

		if delta := compareTwoPages(sourceFile, referenceFile, dummyFile, path); delta > 0 {
			if delta > cs.Delta {
				cs.Delta = delta
				maxDeltaPage = i
			}
			all.Delta = cs.Delta
			// Threshold for "bad" pages kept as before.
			if delta > 0.3 {
				if i > 0 {
					all.Badpages = append(all.Badpages, i)
				}
				cs.Badpages = append(cs.Badpages, i)
			}
		}
	}

	cs.PreviewPage = maxDeltaPage
	all.PreviewPage = maxDeltaPage

	// 8) Emit statuses.
	statuschan <- []compareStatus{cs, all}
}

func mkWebPage(onlyErrorPages bool) error {
	var pages []compareStatus
	if onlyErrorPages {
		pages = cs
	} else {
		pages = allPages
	}

	// Helper: order by multiple keys using 3-way comparisons.
	slices.SortFunc(pages, func(a, b compareStatus) int {
		// BuildError: true before false
		if a.BuildError != b.BuildError {
			// cmp.Compare puts false<true; invert to get true first
			if a.BuildError {
				return -1
			}
			return 1
		}

		// Delta: descending; treat NaN as -∞
		ad, bd := a.Delta, b.Delta
		if math.IsNaN(ad) {
			ad = math.Inf(-1)
		}
		if math.IsNaN(bd) {
			bd = math.Inf(-1)
		}
		if c := cmp.Compare(bd, ad); c != 0 { // reverse for descending
			return c
		}

		// Tie-breaker: Path ascending
		return cmp.Compare(a.Path, b.Path)
	})

	tmpl := `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>speedata compare result</title>
<style>
  body { font-family: system-ui, -apple-system, Segoe UI, Roboto, sans-serif; padding: 1rem 1.5rem; }
  table { border-collapse: collapse; width: 100%; }
  th, td { border-bottom: 1px solid #ddd; padding: 8px 10px; text-align: left; vertical-align: top; }
  th { background: #f6f6f6; position: sticky; top: 0; }
  .num { text-align: right; white-space: nowrap; }
  .badge { display:inline-block; padding:2px 6px; margin:0 4px; font-size:11px; border-radius:4px; border:1px solid #333; }
  .ok { background:#d7f7d7; }
  .warn { background:#ffe9a8; }
  .err  { background:#ffd2d2; }
  .row-err td { background: #fff2f2; }
  .thumb { height: 80px; border: 1px solid #ccc; cursor: zoom-in; }
  .muted { color:#777; }
  .details { cursor:pointer; text-decoration: underline; }
  .hidden { display:none; white-space: pre-wrap; font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; background:#fafafa; border:1px solid #eee; padding:8px; margin-top:6px; }
  /* lightbox */
  .overlay { position: fixed; inset: 0; display: none; align-items: center; justify-content: center; background: rgba(0,0,0,0.7); z-index: 9999; }
  .overlay img { max-width: 95vw; max-height: 95vh; box-shadow: 0 10px 30px rgba(0,0,0,0.6); }
  .overlay.show { display: flex; }
</style>
</head>
<body>

<h1>Compare report</h1>

{{ if not .HasRows }}
  <p class="muted">All comparisons passed. No differences found.</p>
{{ else }}
  <table>
    <thead>
      <tr>
        <th style="width:32%;">Path</th>
        <th class="num" style="width:8%;">Delta</th>
        <th style="width:12%;">Publisher</th>
        <th style="width:10%;">Checksum</th>
        <th style="width:8%;">Struct</th>
        <th style="width:10%;">Compare</th>
        <th style="width:10%;">Bad pages</th>
        <th style="width:12%;">Preview</th>
      </tr>
    </thead>
    <tbody>
      {{ range .CompareStatus -}}
      {{ $path := .Path }}
      <tr class="{{ if .BuildError }}row-err{{ end }}">
        <td><code>{{ .Path }}</code>
          {{ if .BuildError }}
            <div>
              <span class="badge err">sp failed</span>
              <span class="details" onclick="toggleDetails(this)">details</span>
              <div class="hidden">{{ .BuildErrorMsg }}</div>
            </div>
          {{ end }}
        </td>
        <td class="num">{{ if .BuildError }}—{{ else }}{{ .Delta | printf "%.3f" }}{{ end }}</td>
        <td>
          {{ if .BuildError }}
            <span class="badge err">failed</span>
          {{ else }}
            <span class="badge ok">ok</span>
          {{ end }}
        </td>
        <td>
          {{ if .BuildError }}
            <span class="muted">—</span>
          {{ else if .ChecksumEqual }}
            <span class="badge ok">equal</span>
          {{ else }}
            <span class="badge warn">unequal</span>
          {{ end }}
        </td>
        <td>
          {{ if eq .StructMismatch 0 }}
            <span class="muted">—</span>
          {{ else if eq .StructMismatch 1 }}
            <span class="badge ok">ok</span>
          {{ else }}
            <span class="badge err">mismatch</span>
          {{ end }}
        </td>
        <td>
          {{ if .BuildError }}
            <span class="muted">—</span>
          {{ else if .CompareNeeded }}
            <span class="badge warn">cmp run</span>
          {{ else }}
            <span class="badge ok">cmp skip</span>
          {{ end }}
        </td>
<td>
  {{- if .BuildError -}}
    <span class="muted">—</span>
  {{- else if gt (len .Badpages) 0 -}}
    {{- $row := . -}}
    {{- range $i, $p := $row.Badpages -}}
      {{ $p }}{{ if lt $i (sub (len $row.Badpages) 1) }}, {{ end }}
    {{- end -}}
  {{- else -}}
    <span class="muted">—</span>
  {{- end -}}
</td>

<td>
  {{- if or .BuildError (not .CompareNeeded) -}}
    <span class="muted">—</span>
  {{- else -}}
    {{- $img := printf "pagediff-%02d.png" .PreviewPage -}}
    <img class="thumb" src="{{ .Path }}/{{ $img }}" alt="preview" data-full="{{ .Path }}/{{ $img }}">
  {{- end -}}
</td>
      </tr>
      {{- end }}
    </tbody>
  </table>
{{ end }}

<div id="overlay" class="overlay" onclick="this.classList.remove('show')">
  <img id="overlayImg" alt="full-size">
</div>

<script>
  function toggleDetails(el){
    var box = el.nextElementSibling;
    if(!box) return;
    box.classList.toggle('hidden');
  }
  document.addEventListener('click', function (e) {
    var t = e.target;
    if (t && t.matches('img.thumb')) {
      var full = t.getAttribute('data-full');
      var ov = document.getElementById('overlay');
      var img = document.getElementById('overlayImg');
      img.src = full;
      ov.classList.add('show');
    }
  });
  // tiny helper for templating
</script>

</body>
</html>`

	// Helpers for template functions (optional short helpers)
	funcMap := template.FuncMap{
		"len": func(v []int) int { return len(v) },
		"sub": func(a, b int) int { return a - b },
	}

	var buf bytes.Buffer
	t := template.Must(template.New("html").Funcs(funcMap).Parse(tmpl))

	data := struct {
		CompareStatus []compareStatus
		HasRows       bool
	}{
		CompareStatus: pages,
		HasRows:       len(pages) > 0,
	}

	if err := t.Execute(&buf, data); err != nil {
		return err
	}
	outfile := "compare-report.html"
	f, err := os.Create(outfile)
	if err != nil {
		return err
	}
	defer f.Close()
	if _, err = buf.WriteTo(f); err != nil {
		return err
	}
	fmt.Println("Output written to", outfile)
	return nil
}

// Collects statuses until statuschan is closed, then returns.
func getCompareStatus(statuschan <-chan []compareStatus) {
	for st := range statuschan {
		// st[1] = "all pages" entry, st[0] = per-dir entry (only added to cs if there are bad pages or build error)
		allPages = append(allPages, st[1])

		if len(st[0].Badpages) > 0 || st[0].BuildError || st[0].StructMismatch == 2 {
			mutex.Lock()
			cs = append(cs, st[0])
			mutex.Unlock()

			// Optional console summary
			fmt.Println("---------------------------")
			fmt.Println("Finished with comparison in")
			fmt.Println(st[0].Path)
			if st[0].BuildError {
				fmt.Println("Publisher failed.")
			} else {
				if len(st[0].Badpages) > 0 {
					fmt.Println("Comparison failed. Bad pages are:", st[0].Badpages)
					fmt.Println("Max delta is", fmt.Sprintf("%.2f", st[0].Delta))
				}
				if st[0].StructMismatch == 2 {
					fmt.Println("Structure tree mismatch.")
				}
			}
		}
	}
	// Channel closed -> return
}

// Return a filepath.WalkFunc that looks into a directory, runs convert to generate the PNG files from the PDF and
// compares the two resulting files. The function puts the result into the channel compareStatus.
func mkCompare(statuschan chan []compareStatus) filepath.WalkFunc {
	return func(path string, info os.FileInfo, err error) error {
		if info == nil || !info.IsDir() {
			return nil
		}
		if _, err := os.Stat(filepath.Join(path, fmt.Sprintf("%s.pdf", referencefilename))); err == nil {
			wp.Submit(func() { runComparison(path, statuschan) })
		} else if _, err := os.Stat(filepath.Join(path, "layout.xml")); err == nil {
			fmt.Println("Warning: directory", path, "has layout.xml but not reference.pdf")
		}
		return nil
	}
}
