
var fs = require("fs"),
    util = require('util'),
    path = require('path')


function Configuratr() {
	this.options = {}

	// Read multiple files (pass in multiple strings)
	// and ignore if the file does not exist.
	this.read_ignore_errors = function() {
		var config_read = false
		for (var i = 0, j = arguments.length; i < j; i++) {
        	if (path.existsSync(arguments[i])) {
        		config_read = true
            	this.read(arguments[i])
	        }
		}
		return config_read
	}

	this.read = function(filename) {
		var current_section = "options"
		var contents = fs.readFileSync(filename,'utf8').replace(/(\s*#.*|\s*)$/gm,""),
		    lines = contents.split("\n"),
			kv
		for (var i = 0; i < lines.length; i++) {
			var is_new_section = lines[i].match(/\[(.*)\]/)
			if (is_new_section) {
				current_section = is_new_section[1]
				this[current_section] = {}
			}
			kv = lines[i].split(/\s*=\s*/)
			if (kv.length == 2) {
				// we don't need quotation marks around it, so we remove 'em
				kv[1] = kv[1].replace(/^"(.*)"$/,"$1")
				if (this[current_section][kv[0]]) {
					if (typeof(this[current_section][kv[0]]) == "string" || typeof(this[current_section][kv[0]]) == "number" || typeof(this[current_section][kv[0]]) == "boolean" ) {
						this[current_section][kv[0]] = new Array(this[current_section][kv[0]],kv[1])
					} else {
						this[current_section][kv[0]].push(kv[1])
					}
				} else {
					this[current_section][kv[0]] = kv[1]
				}
			}
		};
	}
	this.getString = function (key,section) {
		var current_section = typeof(section) == "undefined" ?  "options" : section
		var tmp = this[current_section][key]
		if (typeof(tmp) == "string") {
			return tmp
		} else if (typeof(tmp) == "object") {
			return tmp.pop()
		} else {
			console.log(typeof(tmp))
		}
	}

	this.getNumber = function (key,section) {
		var current_section = typeof(section) == "undefined" ?  "options" : section
		var tmp = this[current_section][key]
		if (typeof(tmp) == "string") {
			return parseInt(tmp)
		} else if (typeof(tmp) == "number") {
			return tmp
		} else if (typeof(tmp) == "object") {
			return parseInt(tmp.pop())
		} else {
			console.log(typeof(tmp))
		}
	}

	this.getArray = function(key,section) {
		var current_section = typeof(section) == "undefined" ?  "options" : section
		var tmp = this[current_section][key]
		if (util.isArray(tmp)) {
            return tmp
        } else {
            return new Array(tmp)
        }
	}

}

// var cf = new Configuratr()

module.exports = Configuratr
