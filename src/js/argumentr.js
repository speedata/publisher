// argumentr.js - optionparser for node.js

// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do
// so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
// FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

var path    = require("path")
var sprintf = require("./sprintf.js").sprintf

// Return object with argument, parameter, is_optional, short and negate
function split_on (arg) {
    var argument, param,optional,short,negate
    if (arg.match(/^--/)) {
        short = false
    } else if (arg.match(/^-[^-]/)) {
        short = true
    } else {
        // fail
    }
    var init = (short ? 1 : 2)
    if (arg.slice(init,init+3) == "no-") {
        negate = true
        init = init + 3
    }
    var pos = arg.search(/[ =]/)
    if (pos > -1) {
        argument = arg.slice(init,pos)
    } else {
        argument = arg.slice(init)
        return { argument:argument, optional: false, short: short,negate: negate }
    }

    // Now we know that the option requires an argument, it could be optional
    var len = arg.length
    pos++
    if (arg[pos] == "[") {
        pos++
        len--
        optional = true
    } else {
        optional = false
    }
    param = arg.slice(pos,len)
    var ret = { argument:argument, param: param, optional: optional, short: short,negate: negate }
    return ret
}

function set(obj,negate,arg) {
    if (obj.func) {
        obj.func(arg)
    } else if (obj.hash) {
        var objname = (obj.long ? obj.long : obj.short)
        if (arg) {
            obj.hash[objname] = arg
        } else {
            obj.hash[objname] = negate ? false : true 
        }
    }

}

function wordwrap (helptext,wd) {
            var lines = new Array(),
                current_line = undefined,
                current_line_length = 0

            // word wrap
            var helparray = helptext.match(/\S+/g)
            var wd_word
            for (var i = 0; i < helparray.length; i++) {
                wd_word = helparray[i].length
                if (!current_line) {
                    current_line = helparray[i]
                    current_line_length = wd_word
                } else if (wd_word + current_line_length + 1 < wd) {
                    current_line = current_line + " " + helparray[i]
                    current_line_length = current_line_length + wd_word + 1
                } else {
                    lines.push(current_line)
                    current_line = helparray[i]
                    current_line_length = wd_word
                }
            }
            lines.push(current_line)
            return lines
}

function format_and_output (start,stop,dash_short,short,comma,dash_long,long,lines) {
    var formatstring = sprintf("%%-1s%%-1s%%1s %%-2s%%-%d.%ds %%s",start - 8,stop - 8)

    // the formatstring now looks like this: "%-1s%-2s%1s %-2s%-22.71s %s"
    // console.log(formatstring)
    console.log(sprintf(formatstring,dash_short,short, comma,dash_long,long,lines[0]))
    formatstring = sprintf("%%%ds%%s",start - 1)
    for (var i = 1; i < lines.length; i++) {
        console.log(sprintf(formatstring," ", lines[i]))
    };
}

function Argumentr () {
    this.options = { short: {}, long: {}, optionarray: new Array() }
    this.scriptname = path.basename(process.argv[1])
    this.banner = "Usage: " + this.scriptname + " [parameter] command "
    this.start = 30
    this.stop  = 79
    this.extra = new Array()
    this.commands = new Array()


    this.on = function () {
        var option = {}
        this.options.optionarray.push(option)
        option.counter = this.options.optionarray.length
        for (var i = 0; i < arguments.length; i++) {
            var arg = arguments[i]
            if (typeof(arg) == "string" && arg.match(/^--?/)) {
                var ret = split_on(arg)
                //short or long argument
                if (ret.short) {
                    if (this.options.short[ret.argument]) {
                        // short arg already present
                        var opt = this.options.short[ret.argument]
                        this.options.optionarray.splice(opt.counter - 1,1)
                        this.options.long[opt.long] = undefined
                    }
                    this.options.short[ret.argument] = option
                    option.short = ret.argument
                } else {
                    // long argument
                    if (this.options.long[ret.argument]) {
                        // long arg already present
                        var opt = this.options.long[ret.argument]
                        this.options.optionarray.splice(opt.counter - 1,1)
                        this.options.short[opt.short] = undefined

                    }
                    this.options.long[ret.argument] = option
                    option.long = ret.argument
                }
                // the other (short or long option) could have already
                // set the optional/param setting
                option.optional = option.optional || ret.optional
                option.param    = option.param    || ret.param
            } else if (typeof(arg) == "function") {
                option.func = arg
            } else if (typeof(arg) == "string") {
                option.helptext = arg
            } else if (typeof(arg) == "object") {
                option.hash = arg
            } else {
                // console.log(typeof(arg))
            }
        }
    }

    // additional lines 
    this.command = function(command,explanation,dflt) {
        this.commands.push([command,explanation]) 
        if (dflt) {
            this.cmd = command
        }
    }

    // if you give an array or a string to this function, it
    // wiil be parsed instead of process.argv
    this.parse = function(arg) {
        arg = arg || process.argv
        if (typeof(arg)=="string") {
            arg = arg.split(/\s+/)
            arg.unshift("node","path_to_script")
        }
        var i = 2
        var option
        var ret
        while (i < arg.length) {
            if (arg[i].match(/^-/)) {
                ret = split_on(arg[i])
                if (ret.short) {
                    option = this.options.short[ret.argument]
                } else {
                    option = this.options.long[ret.argument]
                }

                if (! option) {
                    return {ok: false, msg:"Unknown option: '" + ( ret.short ? "-" : "--")  + ret.argument + "'"}
                }
                if ( (! ret.param) && (i < arg.length - 1) && (! arg[i+1].match(/^--?/))) {
                    ret.param = arg.splice(i+1,1)[0]
                }
                if (ret.param) {
                    if (option.param) {
                        // OK, we've got a parameter and we expect one
                        set(option,ret.negate,ret.param)
                    } else {
                        // we've got a parameter but didn't expect one,
                        // so let's push it onto the stack
                        this.extra.push(ret.param)
                        set(option,ret.negate)
                    }
                } else {
                    // no parameter found
                    if (option.param && option.optional) {
                        // it's optional, so we can just call our funky function
                        set(option,ret.negate)
                    } else if (option.param && ! option.optional) {
                        // whee! no parameter but its not optional
                        return {ok: false, msg:"Parameter expected but none given: '" + ( ret.short ? "-" : "--")  + ret.argument + "'"}
                    } else {
                        set(option,ret.negate)
                    }
                }
                arg.splice(i,1)
            } else {
                this.extra.push(arg.splice(i,1)[0])
            } 
        }
        var to_delete
        for (var i = 0; i < this.extra.length; i++) {
            for (var j = 0; j < this.commands.length; j++) {
                if ( this.extra[i] == this.commands[j][0]) {
                    this.cmd = this.extra[i]
                    to_delete = i
                }
            };
        };
        if (to_delete) {
            this.extra.splice(to_delete,1)
        }
        return {ok: true}
    }

    this.help = function() {
        var short, long,
            start = this.start,
            stop  = this.stop,
            wd    = stop - start

        console.log(this.banner)
        this.options.optionarray.forEach(function(option) {
            short = option.short || ""
            long  = option.long  || ""
            if (option.long) {
                if (option.param && option.optional) {
                    long = sprintf("%s [=%s]",option.long,option.param)
                } else if (option.param) {
                    long = sprintf("%s=%s",option.long,option.param)
                }
            } else {
                if (option.param && option.optional) {
                    short = sprintf("%s [=%s]",option.short,option.param)
                } else if (option.param) {
                    short = sprintf("%s=%s",option.short,option.param)
                }
            }
            var dash_short = "-",
                dash_long  = "--",
                comma      = ","
            if (short.length == 0 ) {
                dash_short = ""
                comma = ""
            }
            if (long.length == 0) {
                dash_long = ""
                comma = ""
            }

            var lines = wordwrap(option.helptext,wd)
            format_and_output(start,stop,dash_short,short, comma,dash_long,long,lines)
        },this)

        var a
        if (this.commands.length > 0) {
            console.log()
            console.log("Commands")
        }
        this.commands.forEach(function(line){
            a = line[0]
            var lines = wordwrap(line[1],wd)
            format_and_output(start,stop,"","","","",a,lines)
        },this)
    }

}   

var a = new Argumentr()

a.on("-h","--help","Show this help",function() { a.help(); process.exit(0)})

module.exports = a
