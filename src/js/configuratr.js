
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
}

// var cf = new Configuratr()

module.exports = Configuratr
