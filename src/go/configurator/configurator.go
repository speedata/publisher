package configurator

import (
	"os"

	"github.com/speedata/config"
)

// ConfigData is the main data structure for the configurations
type ConfigData struct {
	cfg       []*config.Config
	Filenames []string
}

func (cd *ConfigData) String(section string, str string) string {
	for i := 0; i < len(cd.cfg); i++ {
		s, _ := cd.cfg[i].String(section, str)
		if s != "" {
			return s
		}
	}
	return ""
}

// ReadFile reads the config file at the file name f.
func (cd *ConfigData) ReadFile(f string) error {
	c, err := config.ReadDefault(f)
	if c != nil {
		cd.Filenames = append(cd.Filenames, f)
		// We add a default variable called 'projectdir'
		// that contains the absolute path of the directory
		// where the publisher.cfg resides
		wd, _ := os.Getwd()
		c.AddOption("", "projectdir", wd)
		cd.cfg = append(cd.cfg, c)
		return nil
	}
	return err
}

// ReadFiles tries to read all files given as file names but does not fail in case an error occurs.
func ReadFiles(a ...string) (*ConfigData, error) {
	cfgData := new(ConfigData)

	for _, cfgfile := range a {
		// try each configuration file, ignore errors
		c, _ := config.ReadDefault(cfgfile)
		if c != nil {
			cfgData.Filenames = append(cfgData.Filenames, cfgfile)
			cfgData.cfg = append(cfgData.cfg, c)
		}
	}
	return cfgData, nil
}
