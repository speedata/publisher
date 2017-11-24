
require "pathname"
require 'rake/clean'

CLEAN.include("publisher.pdf","publisher.log","publisher.protocol","publisher.vars")
CLOBBER.include("build/sourcedoc","src/go/sp/sp","src/go/sp/docgo", "src/go/sp/bin","src/go/sp/pkg")

installdir = Pathname.new(__FILE__).join("..")
srcdir   = installdir.join("src")
builddir = installdir.join("build")
@versions = {}

File.read("version").each_line do |line|
	product,versionnumber = line.chomp.split(/=/) # / <-- ignore this slash
	@versions[product]=versionnumber
end

ENV['GOPATH'] = "#{srcdir}/go"


def build_go(srcdir,destbin,goos,goarch,targettype)
	if goarch
		ENV['GOARCH'] = goarch
	end
	if goos
		ENV['GOOS'] = goos
	end
	publisher_version = @versions['publisher_version']
	binaryname = goos == "windows" ? "sp.exe" : "sp"
    # Now compile the go executable
    separator = `go version`.match('go\d\.(\d)')[1].to_i < 5 ? " " : "="
	cmdline = "go build -ldflags '-X main.dest#{separator}#{targettype} -X main.version#{separator}#{publisher_version}' -o #{destbin}/#{binaryname} sp/main"
	sh cmdline do |ok, res|
		if ! ok
	    	puts "Go compilation failed"
	    	return false
	    end
	end
	return true
end

desc "Build sphelper program"
task :sphelper do
	ENV["GOBIN"] = "#{installdir}/bin"
	separator = `go version`.match('go\d\.(\d)')[1].to_i < 5 ? " " : "="
	sh " go install -ldflags \"-X main.basedir#{separator}#{installdir} -X main.separator#{separator}#{separator} -s\"  sphelper/sphelper"
end

desc "Show rake description"
task :default do
	puts
	puts "Run 'rake -T' for a list of tasks."
	puts
	puts "1: Use 'rake build' to build the 'sp' binary. That should be\n   the starting point."
	puts "2: Then try to build the documentation by running 'rake doc'\n   followed by 'sp doc' to read the documentation."
	puts
end

desc "Compile and install necessary software"
task :build => [:sphelper] do
	sh "#{installdir}/bin/sphelper build"
end

desc "Generate documentation"
task :doc => [:sphelper] do
	sh "#{installdir}/bin/sphelper doc"
	puts "done"
end

desc "Update the examples in the documentation"
task :updateexamples do
	Dir.chdir(installdir.join("doc","manual")) do
		Dir.glob('doc/examples-*/**').select { |f| File.directory? f}.each do |dir|
			puts "Update example in #{dir}"
			Dir.chdir(dir) do
				`sp`
				`sp clean`
				`convert publisher.pdf[0] -thumbnail 240  thumbnail.png`
			end
		end
	end
end

desc "Generate schema from master"
task :schema => [:sphelper] do
  # generate the lua translation + schema
  sh "#{installdir}/bin/sphelper genschema"
end

desc "Source documentation"
task :sourcedoc => [:sphelper] do
    sh "#{installdir}/bin/sphelper sourcedoc"
	if RUBY_PLATFORM =~ /darwin/
		sh "open #{builddir}/sourcedoc/publisher.html"
	else
		puts "Generated source documentation in \n#{builddir}/sourcedoc/publisher.html"
	end
end

desc "Update gh-pages"
task :ghpages => [:sphelper] do
	sh "#{installdir}/bin/sphelper doc"
	cp_r "#{builddir}/manual","webpage"
	sh "#{installdir}/bin/sphelper dashdoc"

	IO.write("webpage/speedata_Publisher_(en).xml","<entry>\n  <version>#{@versions['publisher_version']}</version>\n  <url>https://download.speedata.de/publisher/dashdoc/speedatapublisher-en.tgz</url>\n</entry>\n")
	IO.write("webpage/speedata_Publisher_(de).xml","<entry>\n  <version>#{@versions['publisher_version']}</version>\n  <url>https://download.speedata.de/publisher/dashdoc/speedatapublisher-de.tgz</url>\n</entry>\n")
end

task :mkdashzip => [:sphelper] do
	sh "#{installdir}/bin/sphelper doc"
	cp_r "#{builddir}/manual","webpage"
	sh "#{installdir}/bin/sphelper dashdoc"

	Dir.chdir(builddir) do
		sh "tar --exclude='.DS_Store' -czf ../webpage/speedatapublisher-de.tgz speedatapublisher-de.docset"
		sh "tar --exclude='.DS_Store' -czf ../webpage/speedatapublisher-en.tgz speedatapublisher-en.docset"
	end
end

# For now: only a small test
desc "Test source code"
task :test do
	ENV["LUA_PATH"] = "#{srcdir}/lua/?.lua;#{installdir}/lib/?.lua;#{installdir}/test/?.lua"
	ENV["PUBLISHER_BASE_PATH"] = installdir.to_s
	inifile = srcdir.join("sdini.lua")
	sh "texlua --lua=#{inifile} #{installdir}/bin/luatest tc_xpath.lua"
end

desc "Run quality assurance"
task :qa do
	sh "#{installdir}/bin/sp compare #{installdir}/qa"
end

desc "Clean QA intermediate files"
task :cleanqa do
	FileUtils.rm Dir.glob("qa/**/pagediff-*.png")
	FileUtils.rm Dir.glob("qa/**/reference-*.png")
	FileUtils.rm Dir.glob("qa/**/source-*.png")
	FileUtils.rm Dir.glob("qa/**/publisher.vars")
	FileUtils.rm Dir.glob("qa/**/publisher.status")
	FileUtils.rm Dir.glob("qa/**/publisher.protocol")
	FileUtils.rm Dir.glob("qa/**/publisher.pdf")
end

# The environment variable LUATEX_BIN must point to a directory with the following structure
# ├── darwin
# │   ├── amd64
# │   └── 386
# ├── linux
# │   ├── amd64
# │   └── 386
# └── windows
#     ├── amd64
#     └── 386
#
# and each of these amd64/386 directories look like this:
# ├── 0_79_1
# │   ├── kpathsea620w64.dll
# │   ├── lua52w64.dll
# │   ├── luatex.dll
# │   ├── luatex.exe
# │   └── msvcr100.dll
# └── default -> 0_79_1/
#
# The task looks for a directory named "default" and uses the binary files in that directory
desc "Make ZIP files for all platforms and installer for windows"
task :dist => [:sphelper] do
	sh "#{installdir}/bin/sphelper dist windows/amd64 windows/386 linux/amd64 linux/386 darwin/amd64 darwin/386"
end

desc "Make ZIP files - set NODOC=true for stripped zip file"
task :zip => [:sphelper] do
	srcbindir = ENV["LUATEX_BIN"] || ""
	if ! test(?d,srcbindir) then
		puts "Environment variable LUATEX_BIN does not exist.\nMake sure it points to a path which contains `luatex'.\nUse like this: rake zip LUATEX_BIN=/path/to/bin\nAborting"
		next
	end
	publisher_version = @versions['publisher_version']

	dest="#{builddir}/speedata-publisher"
	targetbin="#{dest}/bin"
	targetshare="#{dest}/share"
	targetsw=File.join(dest,"sw")
	targetfonts=File.join(targetsw,"fonts")
	targetschema=File.join(targetshare,"schema")
	rm_rf dest
	mkdir_p dest
	mkdir_p targetbin
	mkdir_p File.join(targetsw,"img")
	mkdir_p targetschema
	mkdir_p targetsw
	if ENV['NODOC'] != "true" then
		Rake::Task["doc"].execute
		cp_r "#{builddir}/manual",File.join(targetshare,"doc")
	end
	platform = nil
	arch = nil
	execfilename = "sdluatex"
	if test(?f, srcbindir +"/sdluatex") then
		cp_r(srcbindir +"/sdluatex",targetbin)
	elsif test(?f,srcbindir +"/luatex.exe") then
		cp_r(Dir.glob(srcbindir +"/*") ,targetbin)
		File.open(targetbin + "/texmf.cnf", "w") { |file| file.write("#dummy\n") }
		platform = "windows"
		execfilename = "luatex.exe"
	elsif test(?f,srcbindir +"/sdluatex.exe") then
		cp_r(Dir.glob(srcbindir +"/*") ,targetbin)
		File.open(targetbin + "/texmf.cnf", "w") { |file| file.write("#dummy\n") }
		platform = "windows"
		execfilename = "sdluatex.exe"
	elsif test(?f,srcbindir +"/luatex") then
		cp_r(srcbindir +"/luatex","#{targetbin}/sdluatex")
	end
	cmd = "file #{targetbin}/#{execfilename}"
	res = `#{cmd}`.gsub(/^.*luatex.*:/,'')
	case res
	when /Mach-O/
		platform = "darwin"
	when /Linux/
		platform = "linux"
	end
	case res
	when /x86-64/,/x86_64/,/64-bit/,/PE32\+/
		arch = "amd64"
	when /32-bit/,/80386/,/i386/
		arch = "386"
	end
	if !platform or !arch then
		puts "Could not determine architecture (amd64/386) or platform (windows/linux/darwin)"
		puts "This is the output of 'file':"
		puts res
		next
	end

	zipname = "speedata-publisher-#{platform}-#{arch}-#{publisher_version}.zip"
	rm_rf File.join(builddir,zipname)

	if build_go(srcdir,targetbin,platform,arch,"directory") == false then next end
	cp_r(File.join("fonts"),targetfonts)
	cp_r(Dir.glob("img/*"),File.join(targetsw,"img"))
	cp_r(File.join("lib"),targetshare)
	cp_r(File.join("schema","layoutschema-en.rng"),targetschema)
	cp_r(File.join("schema","layoutschema-de.rng"),targetschema)

	Dir.chdir("src") do
		cp_r(["tex","hyphenation"],targetsw)
		# do not copy every Lua file to the dest
		# and leave out .gitignore and others
		Dir.glob("**/*.lua").reject { |x|
		    x =~  /viznode|fileutils/
		}.each { |x|
		  FileUtils.mkdir_p(File.join(targetsw , File.dirname(x)))
		  FileUtils.cp(x,File.join(targetsw,File.dirname(x)))
		}
	end
	sh "#{installdir}/bin/sphelper mkreadme #{platform} #{dest}"
	dirname = "speedata-publisher"
	cmdline = "zip -rq #{zipname} #{dirname}"
	Dir.chdir("build") do
		puts cmdline
		puts `#{cmdline}`
	end
end


desc "Prepare a .deb directory"
task :deb => [:sphelper] do
	srcbindir = ENV["LUATEX_BIN"] || ""
	if ! test(?d,srcbindir) then
		puts "Environment variable LUATEX_BIN does not exist.\nMake sure it points to a path which contains `luatex'.\nUse like this: rake zip LUATEX_BIN=/path/to/bin\nAborting"
		next
	end
	publisher_version = @versions['publisher_version']

	destdir      = builddir.join("deb")
	targetbin    = destdir.join("usr","bin")
	targetdoc    = destdir.join("usr","share","doc","speedata-publisher")
	targetshare  = destdir.join("usr","share")
	targetfonts  = targetshare.join("speedata-publisher", "fonts")
	targetimg    = targetshare.join("speedata-publisher", "img")
	targetlib    = targetshare.join("speedata-publisher", "lib")
	targetschema = targetshare.join("speedata-publisher", "schema")
	targetsw     = targetshare.join("speedata-publisher", "sw")

	rm_rf destdir
	Rake::Task["doc"].execute

	mkdir_p targetbin
	mkdir_p targetdoc
	mkdir_p targetfonts
	mkdir_p targetimg
	mkdir_p targetlib
	mkdir_p targetschema
	mkdir_p targetsw


	cp_r "#{builddir}/manual/.",targetdoc

	platform = nil
	arch = nil
	execfilename = "sdluatex"

	if test(?f, srcbindir +"/sdluatex") then
		cp_r(srcbindir +"/sdluatex",targetbin)
	else
		puts "copying failed, #{srcbindir}"
		next
	end
	cmd = "file #{targetbin}/#{execfilename}"
	res = `#{cmd}`.gsub(/^.*luatex.*:/,'')
	case res
	when /Linux/
		platform = "linux"
	end
	case res
	when /x86-64/,/x86_64/,/64-bit/
		arch = "amd64"
		debarch = arch
	when /32-bit/,/80386/,/i386/
		arch = "386"
		debarch = "i386"
	end
	if platform != "linux" then
		puts "platform is not linux"
		next
	end
	if !arch then
		puts "Could not determine architecture (amd64/386)"
		puts "This is the output of 'file':"
		puts res
		next
	end

	if build_go(srcdir,targetbin,platform,arch,"linux-usr") == false then next end

	cp_r("fonts/.",targetfonts)
	cp_r(Dir.glob("img/*"),targetimg)
	cp_r("lib/.",targetlib)
	cp_r(File.join("schema","layoutschema-en.rng"),targetschema)
	cp_r(File.join("schema","layoutschema-de.rng"),targetschema)

	Dir.chdir("src") do
		cp_r(["tex","hyphenation"],targetsw)
		# do not copy every Lua file to the dest
		# and leave out .gitignore and others
		Dir.glob("**/*.lua").reject { |x|
		    x =~  /viznode|fileutils|Shopify/
		}.each { |x|
		  mkdir_p(targetsw.join(File.dirname(x)))
		  cp(x,targetsw.join(File.dirname(x)))
		}
	end
    # control-file
    mkdir_p destdir.join("DEBIAN")
    size = `du -ks #{destdir}/usr | cut -f 1`.chomp
    File.open(destdir.join("DEBIAN","control"), "w") do |f|
		f << %Q{Package: speedata-publisher
	        Version: #{publisher_version}
	        Section: text
	        Priority: optional
	        Architecture: #{debarch}
	        Installed-Size: #{size}
	        Maintainer: speedata <info@speedata.de>
	        Description: speedata publisher
	        }.gsub(/^	        /,"")
	end # file.open
end

desc "Show the version number"
task :publisherversion do
	puts @versions['publisher_version']
end
