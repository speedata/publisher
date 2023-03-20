require "pathname"
require 'rake/clean'

CLEAN.include("publisher.pdf","publisher.log","publisher.protocol","publisher.vars")
CLOBBER.include("build/sourcedoc","src/go/sp/sp","src/go/sp/docgo", "src/go/sp/bin","src/go/sp/pkg")

installdir = Pathname.new(__FILE__).join("..")
srcdir   = installdir.join("src")
builddir = installdir.join("build")
ENV['GOBIN'] = installdir.join("bin").to_s
@versions = {}

File.read("version").each_line do |line|
	product,versionnumber = line.chomp.split(/=/) # / <-- ignore this slash
	@versions[product]=versionnumber
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

desc "Build sphelper program"
task :sphelper do
	Dir.chdir(srcdir.join("go")) do
		sh "go install -ldflags \"-X main.basedir=#{installdir} -s\"  speedatapublisher/sphelper/sphelper"
	end
end

desc "Compile and install necessary software"
task :build => [:sphelper] do
	sh "#{installdir}/bin/sphelper build"
end

desc "Compile and install helper library"
task :buildlib => [:sphelper] do
	sh "#{installdir}/bin/sphelper buildlib"
	FileUtils.cp_r("#{builddir}/dylib/.","#{installdir}/lib/")
end

desc "Generate EPUB only"
task :epub => [:sphelper] do
	sh "#{installdir}/bin/sphelper epub"
	puts "done"
end

desc "Generate documentation"
task :doc => [:sphelper] do
	sh "#{installdir}/bin/sphelper doc"
	puts "done"
end

# without ugly urls
desc "Generate site documentation"
task :sitedoc => [:sphelper] do
	sh "#{installdir}/bin/sphelper sitedoc"
	puts "done"
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

# For now: only a small test
desc "Test source code"
task :test do
	ENV["LUA_PATH"] = "#{srcdir}/lua/?.lua;#{installdir}/lib/?.lua;#{installdir}/test/?.lua"
	ENV["PUBLISHER_BASE_PATH"] = installdir.to_s
	ENV["LD_LIBRARY_PATH"] = "#{installdir}/lib"
	inifile = srcdir.join("lua/sdini.lua")
	sh "bin/sdluatex --luaonly --lua=#{inifile} --ini --shell-escape #{installdir}/bin/luatest tc_xpath.lua"
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
	FileUtils.rm Dir.glob("qa/**/publisher.finished")
	FileUtils.rm Dir.glob("qa/**/publisher.protocol")
	FileUtils.rm Dir.glob("qa/**/publisher.pdf")
end

desc "Regenerate reference.pdf for qa"
task :regenerateqa do
	Dir.glob("qa/**/") do |d|
		Dir.chdir(d) do
			if test(?f,"layout.xml") then
				sh "sp -s --jobname reference"
				sh "sp --jobname reference clean"
			end
		end
	end
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
	sh "#{installdir}/bin/sphelper dist windows/amd64 linux/amd64"
end

desc "Prepare a .deb directory"
task :deb => [:sphelper] do
	srcbindir = ENV["LUATEX_BIN"] || ""
	if ! test(?d,srcbindir) then
		puts "Environment variable LUATEX_BIN does not exist.\nMake sure it points to a path which contains `sdluatex'.\nUse like this: rake deb LUATEX_BIN=/path/to/bin\nAborting"
		next
	end
	publisher_version = @versions['publisher_version']

	destdir      = builddir.join("deb")
	targetbin    = destdir.join("usr","bin")
	targetshare  = destdir.join("usr","share")
	targetfonts  = targetshare.join("speedata-publisher", "fonts")
	targetimg    = targetshare.join("speedata-publisher", "img")
	targetlib    = targetshare.join("speedata-publisher", "lib")
	targetschema = targetshare.join("speedata-publisher", "schema")
	targetsw     = targetshare.join("speedata-publisher", "sw")

	rm_rf destdir

	mkdir_p targetbin
	mkdir_p targetfonts
	mkdir_p targetimg
	mkdir_p targetlib
	mkdir_p targetschema
	mkdir_p targetsw


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
	sh "#{installdir}/bin/sphelper builddeb #{platform} #{arch} #{targetbin}/sp"
	sh "#{installdir}/bin/sphelper buildlib"


	cp_r("fonts/.",targetfonts)
	cp_r(Dir.glob("img/*"),targetimg)
	Dir.chdir("lib") do
		Dir.glob("*").reject { |x|
			x =~ /libsplib|imageedit|lib/
		}.each { |x|
			  mkdir_p(targetlib.join(File.dirname(x)))
			  cp(x,targetlib.join(File.dirname(x)))
		}
		cp_r("lib" ,targetlib)
	end
	cp_r(Dir.glob("#{builddir}/dylib/libsplib.so"),targetlib)
	cp_r(Dir.glob("#{builddir}/dylib/luaglue.so"),targetlib)

	cp_r(File.join("schema","layoutschema-en.rng"),targetschema)
	cp_r(File.join("schema","layoutschema-de.rng"),targetschema)
	cp_r(File.join("schema","catalog-schema-en.xml"),targetschema)
	cp_r(File.join("schema","catalog-schema-de.xml"),targetschema)
	cp_r(File.join("schema","layoutschema-en.xsd"),targetschema)
	cp_r(File.join("schema","layoutschema-de.xsd"),targetschema)

	Dir.chdir("src") do
		cp_r(["tex","hyphenation","metapost"],targetsw)
		# do not copy every Lua file to the dest
		# and leave out .gitignore and others
		Dir.glob("lua/**/*.lua").reject { |x|
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
