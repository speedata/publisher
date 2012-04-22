
fs = require("fs")


function Configuratr() {
	this.options = {}
	this.read = function(filename) {
		var contents = fs.readFileSync(filename,'utf8').replace(/(\s*#.*|\s*)$/gm,""),
		    lines = contents.split("\n"),
			kv
		for (var i = 0; i < lines.length; i++) {
			kv = lines[i].split(/\s*=\s*/)
			if (kv.length == 2) {
				if (this.options[kv[0]]) {
					if (typeof(this.options[kv[0]]) == "string" ) {
						this.options[kv[0]] = new Array(this.options[kv[0]],kv[1])
					} else {
						this.options[kv[0]].push(kv[1])
					}
				} else {
					this.options[kv[0]] = kv[1]
				}
			}
		};
	}
	this.getString = function (key) {
		var tmp = this.options[key]
		if (typeof(tmp) == "string") {
			return tmp
		} else if (typeof(tmp) == "object") {
			return tmp.pop()
		} else {
			console.log(typeof(tmp))
		}
	}

	this.getNumber = function (key) {
		var tmp = this.options[key]
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

}

// var cf = new Configuratr()

module.exports = Configuratr
