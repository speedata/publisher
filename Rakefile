
require "pathname"
require 'rake/clean'

CLOBBER.include("build/sourcedoc")

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

desc "Generate schema and translations from master"
task :schema do
  # generate the lua translation
  sh "java -jar #{installdir}/lib/saxon9he.jar -s:#{installdir}/schema/translations.xml -o:#{installdir}/src/lua/translations.lua -xsl:#{installdir}/schema/genluatranslations.xsl" 
  # generate english + german schema
  sh "java -jar #{installdir}/lib/saxon9he.jar -s:#{installdir}/schema/layoutschema-master.rng -o:#{installdir}/schema/layoutschema-en.rng -xsl:#{installdir}/schema/translate_schema.xsl pFrom=en pTo=en"
  sh "java -jar #{installdir}/lib/saxon9he.jar -s:#{installdir}/schema/layoutschema-master.rng -o:#{installdir}/schema/layoutschema-de.rng -xsl:#{installdir}/schema/translate_schema.xsl pFrom=en pTo=de"
end

desc "Source documentation"
task :sourcedoc do
	Dir.chdir("#{srcdir}/lua") do
		sh "#{installdir}/third/locco/locco.lua #{installdir}/build/sourcedoc *lua publisher/*lua common/*lua fonts/*.lua barcodes/*lua"
		puts "Generated source documentation in \n#{installdir}/build/sourcedoc"
	end
end

