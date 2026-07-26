require "pathname"
require 'rake/clean'

CLEAN.include("publisher.pdf","publisher.log","publisher.protocol","publisher.vars")
CLOBBER.include("src/go/sp/sp","src/go/sp/docgo", "src/go/sp/bin","src/go/sp/pkg")

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

desc "Run quality assurance"
task :qa do
	sh "#{installdir}/bin/sp compare #{installdir}/qa"
end

desc "Lint Lua sources with luacheck (fails on warnings too)"
task :luacheck do
	# luacheck exit codes: 0 = clean, 1 = warnings only, >=2 = syntax / config / I/O error.
	# Treat any non-zero exit as a failure so a release can't go out with new warnings.
	sh "luacheck src/lua"
end

desc "Check Lua source formatting with stylua"
task :stylua do
	sh "stylua --check src/lua/"
end

# lua-language-server diagnostics ratchet.
#
#   rake lualint          run the headless check and fail if any diagnostic
#                         code exceeds its count in luals-baseline.json
#   rake lualint:update   write the current counts as the new baseline
#                         (do this deliberately, after real improvements)
#
# The baseline tracks findings per diagnostic code, so a regression in one
# category cannot hide behind an improvement in another. Results depend on
# the lua-language-server version and on the state of the LuaTeX type
# definitions checkout; when upgrading either, re-run lualint:update and
# commit the new baseline together with the upgrade.
#
# Configuration (environment variables):
#   SP_LUALS_BIN      path to lua-language-server. Default: $PATH, then the
#                     newest VS Code sumneko.lua extension.
#   SP_TEXLUATEX_LIB  path to the LuaCATS "tex-luatex/library" directory.
#                     Default: ~/prog/lua/tex-luatex/library. Get it with
#                     git clone https://github.com/LuaCATS/tex-luatex
#
# Check artifacts (config, raw results, log) are written to build/lualint/.

require 'json'

LUALINT_BASELINE = installdir.join("luals-baseline.json")
LUALINT_OUTDIR = installdir.join("build", "lualint")

def lualint_binary
	if ENV["SP_LUALS_BIN"]
		abort "SP_LUALS_BIN is set but not executable: #{ENV['SP_LUALS_BIN']}" unless File.executable?(ENV["SP_LUALS_BIN"])
		return ENV["SP_LUALS_BIN"]
	end
	onpath = `which lua-language-server 2>/dev/null`.chomp
	return onpath unless onpath.empty?
	candidate = Dir.glob(File.join(Dir.home, ".vscode/extensions/sumneko.lua-*/server/bin/lua-language-server")).sort.last
	return candidate if candidate
	abort "lua-language-server not found. Install it or set SP_LUALS_BIN."
end

def lualint_texluatex_lib
	lib = ENV["SP_TEXLUATEX_LIB"] || File.join(Dir.home, "prog/lua/tex-luatex/library")
	unless File.directory?(lib)
		abort "LuaTeX type definitions not found at #{lib}.\n" \
		      "Clone https://github.com/LuaCATS/tex-luatex and set SP_TEXLUATEX_LIB to its library/ directory."
	end
	lib
end

# Runs the headless check over the repository and returns the findings
# grouped by diagnostic code: { "undefined-field" => 383, ... }
def lualint_run_check
	FileUtils.mkdir_p(LUALINT_OUTDIR)
	config = {
		"runtime.version" => "Lua 5.3",
		"diagnostics.severity" => { "duplicate-set-field" => "Hint" },
		"diagnostics.unusedLocalExclude" => ["_*"],
		# Intentional cross-file globals defined in spinit.lua (kept in sync
		# with the "spinit.lua exports" section of .luacheckrc). Keep this in
		# sync with the same list in .luarc.json for the IDE.
		"diagnostics.globals" => [
			"sp_to_bp", "sp_to_pt", "bp_to_sp", "table_textvalue",
			"set_glue", "set_glue_values", "get_glue_value",
			"exit", "quit", "errcount", "warncount",
			"sp_suppressinfo", "luatex_version",
		],
		"workspace.library" => [lualint_texluatex_lib, LUALINT_OUTDIR.join("..", "..", "meta").expand_path.to_s],
	}
	configpath = LUALINT_OUTDIR.join("luarc-check.json")
	File.write(configpath, JSON.pretty_generate(config))

	resultpath = LUALINT_OUTDIR.join("check.json")
	FileUtils.rm_f(resultpath)
	stdoutpath = LUALINT_OUTDIR.join("check.log")
	cmd = [
		lualint_binary, "--check", LUALINT_OUTDIR.join("..", "..").expand_path.to_s,
		"--checklevel=Hint",
		"--configpath=#{configpath}",
		"--check_out_path=#{resultpath}",
		"--logpath=#{LUALINT_OUTDIR.join('log')}",
	]
	puts "Running #{cmd[0]} --check (takes a minute) ..."
	ok = system(*cmd, out: stdoutpath.to_s, err: stdoutpath.to_s)
	log = File.read(stdoutpath)
	unless File.exist?(resultpath)
		# The server writes no result file when the workspace is clean.
		return {} if log.include?("no problems found")
		abort "lua-language-server --check failed (exit #{$?.exitstatus}, ok=#{ok}), see #{stdoutpath}"
	end
	counts = Hash.new(0)
	JSON.parse(File.read(resultpath)).each_value do |diags|
		diags.each { |d| counts[d["code"]] += 1 }
	end
	counts
end

desc "Lua diagnostics ratchet: fail when lua-language-server findings exceed luals-baseline.json"
task :lualint do
	abort "No baseline found. Run 'rake lualint:update' once to create #{LUALINT_BASELINE.basename}." unless File.exist?(LUALINT_BASELINE)
	baseline = JSON.parse(File.read(LUALINT_BASELINE))["codes"] || {}
	current = lualint_run_check
	total = current.values.sum

	violations = current.select { |code, n| n > (baseline[code] || 0) }
	improved = baseline.select { |code, n| current.fetch(code, 0) < n }

	unless violations.empty?
		puts "New lua-language-server findings compared to the baseline:"
		violations.sort_by { |code, _| code }.each do |code, n|
			puts format("  %-24s %d -> %d", code, baseline[code] || 0, n)
		end
		puts "Details: #{LUALINT_OUTDIR.join('check.json')}"
		puts "If the new findings are deliberate (e.g. honest findings surfaced by better annotations),"
		puts "fix or acknowledge them explicitly with 'rake lualint:update'."
		abort "lualint: #{violations.size} diagnostic code(s) above baseline."
	end

	puts "lualint: OK, #{total} finding(s), nothing above baseline."
	unless improved.empty?
		puts "Improvements over the baseline (run 'rake lualint:update' to lock them in):"
		improved.sort_by { |code, _| code }.each do |code, n|
			puts format("  %-24s %d -> %d", code, n, current.fetch(code, 0))
		end
	end
end

namespace :lualint do
	desc "Write the current lua-language-server findings as the new lualint baseline"
	task :update do
		counts = lualint_run_check
		data = {
			"comment" => "Per-code lua-language-server finding counts. Managed by 'rake lualint:update'.",
			"total" => counts.values.sum,
			"codes" => counts.sort_by { |code, n| [-n, code] }.to_h,
		}
		File.write(LUALINT_BASELINE, JSON.pretty_generate(data) + "\n")
		puts "Baseline written: #{LUALINT_BASELINE} (#{data['total']} findings)"
		counts.sort_by { |code, n| [-n, code] }.each { |code, n| puts format("  %5d  %s", n, code) }
	end
end

desc "Run all release-gate checks: luacheck, lualint, stylua format, QA suite"
task :check => [:luacheck, :lualint, :stylua, :qa]

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
desc "Make ZIP files. Set PLATFORM=linux|windows|all (default all)."
task :dist => [:sphelper] do
	targets = case ENV["PLATFORM"] || "all"
	          when "linux"   then "linux/amd64 linux/arm64"
	          when "windows" then "windows/amd64"
	          when "all"     then "windows/amd64 linux/amd64 linux/arm64"
	          else abort "Unknown PLATFORM=#{ENV['PLATFORM']}, expected linux|windows|all"
	          end
	sh "#{installdir}/bin/sphelper dist #{targets}"
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
