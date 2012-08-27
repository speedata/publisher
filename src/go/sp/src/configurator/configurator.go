package configurator

import (
	"config"
)

type ConfigData struct {
	cfg []*config.Config
}

func (cd *ConfigData) String(section string, str string) string {
	for i := 0; i < len(cd.cfg); i++ {
		s,_ := cd.cfg[i].String(section,str)
		if s != "" {
			return s
		}
	}
	return ""
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
