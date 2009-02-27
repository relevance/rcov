# This Rakefile serves as an example of how to use Rcov::RcovTask.
# Take a look at the RDoc documentation (or readme_for_rake) for further
# information.

$:.unshift "lib" if File.directory? "lib"
require 'rcov/rcovtask'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/clean'

# Use the specified rcov executable instead of the one in $PATH
# (this way we get a sort of informal functional test).
# This could also be specified from the command like, e.g.
#   rake rcov RCOVPATH=/path/to/myrcov
ENV["RCOVPATH"] = "bin/rcov"

# The following task is largely equivalent to:
#   Rcov::RcovTask.new
# (really!)
desc "Create a cross-referenced code coverage report."
Rcov::RcovTask.new do |t|
  t.test_files = FileList['test/*_test.rb']
  t.ruby_opts << "-Ilib:ext/rcovrt" # in order to use this rcov
  t.rcov_opts << "--xrefs"  # comment to disable cross-references
  t.verbose = true
end

desc "Analyze code coverage for the FileStatistics class."
Rcov::RcovTask.new(:rcov_sourcefile) do |t|
  t.test_files = FileList['test/file_statistics_test.rb']
  t.verbose = true
  t.rcov_opts << "--test-unit-only"
  t.ruby_opts << "-Ilib:ext/rcovrt" # in order to use this rcov
  t.output_dir = "coverage.sourcefile"
end

Rcov::RcovTask.new(:rcov_ccanalyzer) do |t|
  t.test_files = FileList['test/code_coverage_analyzer_test.rb']
  t.verbose = true
  t.rcov_opts << "--test-unit-only"
  t.ruby_opts << "-Ilib:ext/rcovrt" # in order to use this rcov
  t.output_dir = "coverage.ccanalyzer"
end

desc "Run the unit tests with rcovrt."
if RUBY_PLATFORM == 'java'
  Rake::TestTask.new(:test_rcovrt => ["lib/rcovrt.jar"]) do |t|
    t.libs << "lib"
    t.test_files = FileList['test/*_test.rb']
    t.verbose = true
  end
else
  Rake::TestTask.new(:test_rcovrt => ["ext/rcovrt/rcovrt.so"]) do |t|
    t.libs << "ext/rcovrt"
    t.test_files = FileList['test/*_test.rb']
    t.verbose = true
  end
end

file "ext/rcovrt/rcovrt.so" => FileList["ext/rcovrt/*.c"] do
  ruby "setup.rb config"
  ruby "setup.rb setup"
end

desc "Run the unit tests in pure-Ruby mode ."
Rake::TestTask.new(:test_pure_ruby) do |t|
  t.libs << "ext/rcovrt"
  t.test_files = FileList['test/turn_off_rcovrt.rb', 'test/*_test.rb']
  t.verbose = true
end

desc "Run the unit tests"
task :test => [:test_rcovrt]
#, :test_pure_ruby] disabled since 1.8.5 broke them

desc "Generate rdoc documentation for the rcov library"
Rake::RDocTask.new("rdoc") { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "rcov"
  rdoc.options << "--line-numbers" << "--inline-source"
  rdoc.rdoc_files.include('readme_for_api')
  rdoc.rdoc_files.include('readme_for_rake')
  rdoc.rdoc_files.include('readme_for_rant')
  rdoc.rdoc_files.include('readme_for_vim')
  rdoc.rdoc_files.include('lib/**/*.rb')
}

task :default => :test

desc "install by setup.rb"
task :install do
  sh "sudo ruby setup.rb install"
end


PKG_FILES = ["bin/rcov", "lib/rcov.rb", "lib/rcov/lowlevel.rb", "lib/rcov/xx.rb", "lib/rcov/version.rb", "lib/rcov/rant.rb", "lib/rcov/report.rb", "lib/rcov/rcovtask.rb", "ext/rcovrt/extconf.rb", "ext/rcovrt/rcovrt.c", "ext/rcovrt/callsite.c", "LEGAL", "LICENSE", "Rakefile", "Rantfile", "readme_for_rake", "readme_for_rant", "readme_for_vim", "readme_for_emacs", "readme_for_vim", "readme_for_api", "THANKS", "test/functional_test.rb", "test/file_statistics_test.rb", "test/assets/sample_03.rb", "test/assets/sample_05-new.rb", "test/code_coverage_analyzer_test.rb", "test/assets/sample_04.rb", "test/assets/sample_02.rb", "test/assets/sample_05-old.rb", "test/assets/sample_01.rb", "test/turn_off_rcovrt.rb", "test/call_site_analyzer_test.rb", "test/assets/sample_05.rb", "rcov.vim", "rcov.el", "setup.rb", "BLURB", "CHANGES"]

# gem management tasks  Use these to build the java code before creating the gem package
# this code can also be used to generate the MRI gem.  But I left the gemspec file in too.
spec = Gem::Specification.new do |s|
  s.name = %q{rcov}
  s.version = "0.8.1.5.1"

  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.authors = ["Mauricio Fernandez"]
  s.cert_chain = nil
  s.date = %q{2007-11-21}
  s.default_executable = %q{rcov}
  s.description = %q{rcov is a code coverage tool for Ruby. It is commonly used for viewing overall test unit coverage of target code.  It features fast execution (20-300 times faster than previous tools), multiple analysis modes, XHTML and several kinds of text reports, easy automation with Rake via a RcovTask, fairly accurate coverage information through code linkage inference using simple heuristics, colorblind-friendliness...}
  s.email = %q{mfp@acm.org}
  s.executables = ["rcov"]
  s.extensions = ["ext/rcovrt/extconf.rb"]
  s.platform = Gem::Platform::RUBY
  s.extra_rdoc_files = ["readme_for_api", "readme_for_rake", "readme_for_rant", "readme_for_vim"]
  s.files = PKG_FILES
  s.has_rdoc = true
  s.homepage = %q{http://eigenclass.org/hiki.rb?rcov}
  s.rdoc_options = ["--main", "readme_for_api", "--title", "rcov code coverage tool"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Code coverage analysis tool for Ruby}
  s.test_files = ["test/functional_test.rb", "test/file_statistics_test.rb", "test/code_coverage_analyzer_test.rb", "test/call_site_analyzer_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 1

    if current_version >= 3 then
    else
    end
  else
  end
end

# tasks added in to support generating the JRuby gem.
if RUBY_PLATFORM == 'java'
  spec.platform = "jruby"
  spec.extensions = []
  # add the jruby extension to the file list
  PKG_FILES << "lib/rcovrt.jar"  
  
  def java_classpath_arg
    begin
      require 'java'
      classpath = java.lang.System.getProperty('java.class.path')
    rescue LoadError
    end
  
    if classpath.empty?
      classpath = FileList["#{ENV['JRUBY_HOME']}/lib/*.jar"].join(File::PATH_SEPARATOR)
    end
  
    classpath ? "-cp #{classpath}" : ""
  end
  
  
  CLEAN.include ["ext/java/classes", "lib/rcovrt.jar", "pkg"]
  
  def compile_java
    mkdir_p "ext/java/classes"
    sh "javac -g -target 1.5 -source 1.5 -d ext/java/classes #{java_classpath_arg} #{FileList['ext/java/src/**/*.java'].join(' ')}"
  end
  
  def make_jar
    require 'fileutils'
    lib = File.join(File.dirname(__FILE__), 'lib')
    FileUtils.mkdir(lib) unless File.exists? lib
    sh "jar cf lib/rcovrt.jar -C ext/java/classes/ ." 
  end
  
  file 'lib/rcovrt.jar' => FileList["ext/java/src/*.java"] do
    compile_java
    make_jar
  end
  
  desc "compile the java extension and put it into the lib directory"
  task :java_compile => ["lib/rcovrt.jar"]
  
end

Rake::GemPackageTask.new(spec) do |p|
  p.need_tar = true
  p.gem_spec = spec  
end

# extend the gem task to include the java_compile
if RUBY_PLATFORM == 'java'
  Rake::Task["pkg"].enhance(["java_compile"])
end

# vim: set sw=2 ft=ruby:
