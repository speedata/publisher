
require "pathname"

installdir = Pathname.new(__FILE__).join("..")
srcdir = installdir.join("src")


desc "Compile and install necessary software"
task :build do
	ENV['GOPATH'] = "#{srcdir}/go/sp"
	Dir.chdir(srcdir.join("go","sp")) do
		cmdline = 'go build -ldflags "-X main.dest git -X main.version local"  sp.go'
  		puts `#{cmdline}`
		cmdline = "cp sp #{installdir}/bin"
		puts `#{cmdline}`
	end
end

desc "Generate documentation"
task :doc do
	Dir.chdir(installdir.join("doc","manual")) do
		puts `jekyll`
	end
	print "Now generating command reference from XML..."
	cmdline = "java -jar #{installdir}/lib/saxon9he.jar -s:#{installdir}/doc/commands-xml/commands.xml -o:/dev/null -xsl:#{installdir}/doc/commands-xml/xslt/cmd2html.xsl lang=en builddir=#{installdir}/build/manual"
	`#{cmdline}`
	cmdline = "java -jar #{installdir}/lib/saxon9he.jar -s:#{installdir}/doc/commands-xml/commands.xml -o:/dev/null -xsl:#{installdir}/doc/commands-xml/xslt/cmd2html.xsl lang=de builddir=#{installdir}/build/manual"
	`#{cmdline}`
	puts "done"
end

desc "Remove generated files"
task :clean do
	Dir.chdir(srcdir.join("lua")) do
		FileUtils.rm_rf("docs")
	end
end