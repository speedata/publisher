package main

import (
	"os"
	"path/filepath"
	"testing"

	"speedatapublisher/configurator"
)

// The server passes the number of runs to each job with --runs. Without an
// explicit setting it must be empty, otherwise the default 1 overrides the
// runs attribute of Options in the layout.
func TestServerRuns(t *testing.T) {
	testdata := []struct {
		name    string
		cfgfile string
		cmdline string
		want    string
	}{
		{"nothing set", "[server]\naddress=127.0.0.1\n", "", ""},
		{"no config file", "", "", ""},
		{"top level of publisher.cfg", "runs = 2\n[server]\naddress=127.0.0.1\n", "", "2"},
		{"section server", "[server]\nruns = 3\n", "", "3"},
		{"command line", "[server]\nruns = 3\n", "4", "4"},
	}
	savedOptions, savedCfg := options, cfg
	defer func() { options, cfg = savedOptions, savedCfg }()

	for _, td := range testdata {
		t.Run(td.name, func(t *testing.T) {
			options = map[string]string{}
			if td.cmdline != "" {
				options["runs"] = td.cmdline
			}
			cfg = &configurator.ConfigData{}
			if td.cfgfile != "" {
				fn := filepath.Join(t.TempDir(), "publisher.cfg")
				if err := os.WriteFile(fn, []byte(td.cfgfile), 0o644); err != nil {
					t.Fatal(err)
				}
				if err := cfg.ReadFile(fn); err != nil {
					t.Fatal(err)
				}
			}
			if got := getOptionSectionNoDefault("runs", "server"); got != td.want {
				t.Errorf("runs = %q, want %q", got, td.want)
			}
		})
	}
}
