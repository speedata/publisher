package configurator

import (
	"os"

	"github.com/speedata/config"
)

type ConfigData struct {
	cfg []*config.Config
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

func (cd *ConfigData) ReadFile(f string) error {
	c, err := config.ReadDefault(f)
	if c != nil {
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

func ReadFiles(a ...string) (*ConfigData, error) {
	cfgData := new(ConfigData)
	for _, cfgfile := range a {
		// try each configuration file, ignore errors
		c, _ := config.ReadDefault(cfgfile)
		if c != nil {
			cfgData.cfg = append(cfgData.cfg, c)
		}
	}
	return cfgData, nil
}
