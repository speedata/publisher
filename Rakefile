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

desc "Generate documentation (reference docs and changelog for Hugo)"
task :doc => [:sphelper] do
	sh "#{installdir}/bin/sphelper doc"
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

desc "Lint Lua sources with luacheck"
task :luacheck do
	# luacheck exit codes: 0 = clean, 1 = warnings only, >=2 = syntax / config / I/O error.
	# Treat warnings as a successful run so the report is shown without breaking the task.
	ok = system("luacheck src/lua")
	status = $?.exitstatus
	fail "luacheck failed (exit #{status})" if !ok && status >= 2
end

desc "Clean QA intermediate files"
task :cleanqa do
	FileUtils.rm Dir.glob("qa/**/pagediff-*.png")
	FileUtils.rm Dir.glob("qa/**/reference-*.png")
	FileUtils.rm Dir.glob("qa/**/source-*.png")
	FileUtils.rm Dir.glob("qa/**/publisher.vars")
	FileUtils.rm Dir.glob("qa/**/publisher.status")
	FileUtils.rm Dir.glob("qa/**/publisher.finished")
	FileUtils.rm Dir.glob("qa/**/publisher-protocol.xml")
	FileUtils.rm Dir.glob("qa/**/publisher-aux.xml")
	FileUtils.rm Dir.glob("qa/**/publisher.protocol")
	FileUtils.rm Dir.glob("qa/**/publisher.pdf")
	FileUtils.rm Dir.glob("qa/**/publisher-struct.xml")
	FileUtils.rm Dir.glob("qa/**/compare-report.html")
end

desc "Regenerate reference.pdf for qa"
task :regenerateqa do
	Dir.glob("qa/**/") do |d|
		Dir.chdir(d) do
			if test(?f,"layout.xml") then
				puts "=== #{d} ==="
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
	sh "#{installdir}/bin/sphelper dist windows/amd64 linux/amd64 linux/arm64"
end

desc "Create a customized directory strcuture for distribution"
task :distcustom => [:sphelper] do
	# This should be taken as a blueprint for creating your own directory
	# structure. Instructions: build the sphelper binary,
	# then set the environment variables, and run
	#   sphelper distcutom linux/amd64
	# (replace the target of course)

	# for building the source tree
	ENV['SP_BUILDDIR_SW'] = "/tmp/build/sw"
	ENV['SP_BUILDDIR_SHARE'] = "/tmp/build/share"
	ENV['SP_BUILDDIR_BIN'] = "/tmp/build/bin"

	# lookup paths for the executable
	ENV['SP_DESTDIR_SW'] = "/usr/src/speedata-publisher"
	ENV['SP_DESTDIR_SHARE'] = "/usr/share"
	ENV['SP_DESTDIR_BIN'] = "/usr/bin"
	sh "#{installdir}/bin/sphelper distcustom linux/amd64"
end

desc "Show the version number"
task :publisherversion do
	puts @versions['publisher_version']
end
