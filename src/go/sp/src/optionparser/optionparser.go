package optionparser

import (
	"errors"
	"fmt"
	"os"
	"regexp"
	"strings"
)

// A command is a non-dash option (with a helptext)
type command struct {
	name     string
	helptext string
}

// The instance of an optionParser
type optionParser struct {
	Extra    []string
	Banner   string
	Start    int
	Stop     int
	options  []*allowedOptions
	short    map[string]*allowedOptions
	long     map[string]*allowedOptions
	commands []command
}

type argumentDescription struct {
	argument string
	param    string
	optional bool
	short    bool
	negate   bool
}

type allowedOptions struct {
	optional         bool
	param            string
	short            string
	long             string
	bool_parameter   bool
	function         func(string)
	function_no_args func()
	boolvalue        *bool
	stringmap        map[string]string
	helptext         string
}

// Return true if s starts with a dash ('-s' for example)
func isOption(s string) bool {
	io := regexp.MustCompile("^-")
	return io.MatchString(s)
}

func wordwrap(s string, wd int) []string {
	// if the string is shorter than the width, we can just return it
	if len(s) <= wd {
		return []string{s}
	}

	// Otherwise, we return the first part
	// split at the last occurence of space before wd
	stop := strings.LastIndex(s[0:wd], " ")

	// no space found in the next wd characters, impossible to split
	if stop < 0 {
		stop = strings.Index(s, " ")
		if stop < 0 { // no space found in the remaining characters
			return []string{s}
		}
	}
	a := []string{s[0:stop]}
	j := wordwrap(s[stop+1:], wd)
	return append(a, j...)
}

// Analyse the given argument such as '-s' or 'foo=bar' and 
// return an argumentDescription
func split_on(arg string) *argumentDescription {
	var (
		argument string
		param    string
		optional bool
		short    bool
		negate   bool
	)

	double_dash := regexp.MustCompile("^--")
	single_dash := regexp.MustCompile("^-[^-]")

	if double_dash.MatchString(arg) {
		short = false
	} else if single_dash.MatchString(arg) {
		short = true
	} else {
		panic("can't happen")
	}

	var init int
	if short {
		init = 1
	} else {
		init = 2
	}
	if len(arg) > init+2 {
		if arg[init:init+3] == "no-" {
			negate = true
			init = init + 3
		}
	}

	re := regexp.MustCompile("[ =]")
	loc := re.FindStringIndex(arg)
	if len(loc) == 0 {
		// no optional parameter, we know everything we need to know
		return &argumentDescription{
			argument: arg[init:],
			optional: false,
			short:    short,
			negate:   negate,
		}
	}

	// Now we know that the option requires an argument, it could be optional
	argument = arg[init:loc[0]]
	pos := loc[1]
	length := len(arg)

	if arg[loc[1]:loc[1]+1] == "[" {
		pos++
		length--
		optional = true
	} else {
		optional = false
	}
	param = arg[pos:length]

	a := argumentDescription{
		argument,
		param,
		optional,
		short,
		negate,
	}
	return &a
}

// prints the nice help output
func format_and_output(start int, stop int, dash_short string, short string, comma string, dash_long string, long string, lines []string) {
	formatstring := fmt.Sprintf("%%-1s%%-1s%%1s %%-2s%%-%d.%ds %%s\n", start-8, stop-8)
	// the formatstring now looks like this: "%-1s%-2s%1s %-2s%-22.71s %s"
	fmt.Printf(formatstring, dash_short, short, comma, dash_long, long, lines[0])
	if len(lines) > 0 {
		formatstring = fmt.Sprintf("%%%ds%%s\n", start-1)
		for i := 1; i < len(lines); i++ {
			fmt.Printf(formatstring, " ", lines[i])
		}
	}
}

func set(obj *allowedOptions, has_no_prefix bool, param string) {
	// fmt.Printf("set: %+v\n", obj)
	if obj.function != nil {
		obj.function(param)
	}
	if obj.stringmap != nil {
		var name string
		var value string
		switch {
		case obj.long != "":
			name = obj.long
		case obj.short != "":
			name = obj.short
		}
		// return error if no name given

		if param != "" {
			value = param
		} else {
			if has_no_prefix {
				value = "false"
			} else {
				value = "true"
			}
		}
		obj.stringmap[name] = value
	}
	if obj.function_no_args != nil {
		obj.function_no_args()
	}
	if obj.boolvalue != nil {
		if has_no_prefix {
			*obj.boolvalue = false
		} else {
			*obj.boolvalue = true
		}

	}
}

func (op *optionParser) Command(cmd string, helptext string) {
	cmds := command{cmd, helptext}
	op.commands = append(op.commands, cmds)
}

func (op *optionParser) On(a ...interface{}) {
	option := new(allowedOptions)
	op.options = append(op.options, option)
	for _, i := range a {
		switch x := i.(type) {
		case string:
			// a short option, a long option or a help text
			if isOption(x) {
				ret := split_on(x)
				if ret.short {
					// short argument ('-s')
					op.short[ret.argument] = option
					option.short = ret.argument
				} else {
					// long argument ('--something')
					op.long[ret.argument] = option
					option.long = ret.argument
				}
				if ret.optional {
					option.optional = true
				}
				if ret.param != "" {
					option.param = ret.param
				}
				if ret.negate {
					option.bool_parameter = true
				}
			} else {
				// a string, probably the help text
				option.helptext = x
			}
		case func(string):
			option.function = x
		case func():
			option.function_no_args = x
		case *bool:
			option.boolvalue = x
		case map[string]string:
			option.stringmap = x
		default:
			fmt.Printf(" unknown: %#v\n", x)

		}
	}
}

func (op *optionParser) Parse() error {
	i := 1
	for i < len(os.Args) {
		if isOption(os.Args[i]) {
			ret := split_on(os.Args[i])

			var option *allowedOptions
			if ret.short {
				option = op.short[ret.argument]
			} else {
				option = op.long[ret.argument]
			}

			if option == nil {
				return errors.New("Unknown option " + ret.argument)
			}

			// the parameter in ret.param is only set by `split_on()` when used with
			// the equan sign: "--foo=bar". If the user gives a parameter with "--foo bar"
			// it is not in ret.param. So we look at the next thing in our os.Args array
			// and if its not a parameter (starting with `-`), we take this as the perhaps
			// optional parameter
			if ret.param == "" && i < len(os.Args)-1 && !isOption(os.Args[i+1]) {
				// next could be a parameter
				ret.param = os.Args[i+1]
				// delete this possible parameter from the os.Args list
				os.Args = append(os.Args[:i+1], os.Args[i+2:]...)

			}

			if ret.param != "" {
				if option.param != "" {
					// OK, we've got a parameter and we expect one
					set(option, ret.negate, ret.param)
				} else {
					// we've got a parameter but didn't expect one,
					// so let's push it onto the stack
					op.Extra = append(op.Extra, ret.param)
					set(option, ret.negate, "")
					// fmt.Printf("extra now %#v\n",op.Extra)
				}
			} else {
				// no parameter found
				if option.param != "" {
					// parameter expected
					if !option.optional {
						// No parameter found but expected
						return errors.New("Parameter expected but none given " + ret.argument)
					}
				}
				set(option, ret.negate, "")
			}
		} else {
			// not an option, we push it onto the extra array
			op.Extra = append(op.Extra, os.Args[i])
		}
		i++
	}
	return nil
}

// Print help text generated from the
// "On" commands
func (op *optionParser) Help() {
	fmt.Println(op.Banner)
	wd := op.Stop - op.Start
	for _, o := range op.options {
		short := o.short
		long := o.long
		if o.bool_parameter {
			long = "[no-]" + o.long
		}
		if o.long != "" {
			if o.param != "" {
				if o.optional {
					long = fmt.Sprintf("%s[=%s]", o.long, o.param)
				} else {
					long = fmt.Sprintf("%s=%s", o.long, o.param)
				}
			}
		} else {
			// short
			if o.param != "" {
				if o.optional {
					long = fmt.Sprintf("%s[=%s]", o.long, o.param)
				} else {
					long = fmt.Sprintf("%s=%s", o.long, o.param)
				}
			}
		}
		dash_short := "-"
		dash_long := "--"
		comma := ","
		if short == "" {
			dash_short = ""
			comma = ""
		}
		if long == "" {
			dash_long = ""
			comma = ""
		}
		lines := wordwrap(o.helptext, wd)
		format_and_output(op.Start, op.Stop, dash_short, short, comma, dash_long, long, lines)
	}
	if len(op.commands) > 0 {
		fmt.Println("\nCommands")
		for _, cmd := range op.commands {
			lines := wordwrap(cmd.helptext, wd)
			format_and_output(op.Start, op.Stop, "", "", "", "", cmd.name, lines)
		}
	}
}

func NewOptionParser() *optionParser {
	a := optionParser{}
	a.Extra = []string{}
	a.Banner = "Usage: [parameter] command"
	a.Start = 30
	a.Stop = 79
	a.short = map[string]*allowedOptions{}
	a.long = map[string]*allowedOptions{}
	a.commands = make([]command, 0, 10)
	a.On("-h", "--help", "Show this help", func() { a.Help(); os.Exit(0) })
	return &a
}
