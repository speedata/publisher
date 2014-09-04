package config

type Config struct {
	Basedir string
}

func NewConfig() *Config {
	return &Config{}
}
