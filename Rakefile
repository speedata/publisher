
require "pathname"
require 'rake/clean'

CLOBBER.include("src/lua/docs")

installdir = Pathname.new(__FILE__).join("..")
srcdir = installdir.join("src")


desc "Compile and install necessary software"
task :build do
	ENV['GOPATH'] = "#{srcdir}/go/sp"
	Dir.chdir(srcdir.join("go","sp")) do
		puts "Building (and copying) sp binary..."
  		sh 'go build -ldflags "-X main.dest git -X main.version local"  sp.go'
		cp("sp","#{installdir}/bin")
  		puts "...done"
	end
end

desc "Generate documentation"
task :doc do
	Dir.chdir(installdir.join("doc","manual")) do
		sh "jekyll"
	end
	print "Now generating command reference from XML..."
	sh "java -jar #{installdir}/lib/saxon9he.jar -s:#{installdir}/doc/commands-xml/commands.xml -o:/dev/null -xsl:#{installdir}/doc/commands-xml/xslt/cmd2html.xsl lang=en builddir=#{installdir}/build/manual"
	sh "java -jar #{installdir}/lib/saxon9he.jar -s:#{installdir}/doc/commands-xml/commands.xml -o:/dev/null -xsl:#{installdir}/doc/commands-xml/xslt/cmd2html.xsl lang=de builddir=#{installdir}/build/manual"
	puts "done"
end
