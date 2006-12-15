# This Rakefile serves as an example of how to use Rcov::RcovTask.
# Take a look at the RDoc documentation (or README.rake) for further
# information.

$:.unshift "lib" if File.directory? "lib"
require 'rcov/rcovtask'
require 'rake/testtask'
require 'rake/rdoctask'

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
  t.test_files = FileList['test/test*.rb']
  t.ruby_opts << "-Ilib:ext/rcovrt" # in order to use this rcov
  t.rcov_opts << "--xrefs"  # comment to disable cross-references
  t.verbose = true
end

desc "Analyze code coverage for the FileStatistics class."
Rcov::RcovTask.new(:rcov_sourcefile) do |t|
  t.test_files = FileList['test/test_FileStatistics.rb']
  t.verbose = true
  t.rcov_opts << "--test-unit-only"
  t.ruby_opts << "-Ilib:ext/rcovrt" # in order to use this rcov
  t.output_dir = "coverage.sourcefile"
end

Rcov::RcovTask.new(:rcov_ccanalyzer) do |t|
  t.test_files = FileList['test/test_CodeCoverageAnalyzer.rb']
  t.verbose = true
  t.rcov_opts << "--test-unit-only"
  t.ruby_opts << "-Ilib:ext/rcovrt" # in order to use this rcov
  t.output_dir = "coverage.ccanalyzer"
end

desc "Run the unit tests with rcovrt."
Rake::TestTask.new(:test_rcovrt => ["ext/rcovrt/rcovrt.so"]) do |t|
  t.libs << "ext/rcovrt"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

file "ext/rcovrt/rcovrt.so" => FileList["ext/rcovrt/*.c"] do
  ruby "setup.rb config"
  ruby "setup.rb setup"
end

desc "Run the unit tests in pure-Ruby mode ."
Rake::TestTask.new(:test_pure_ruby) do |t|
  t.libs << "ext/rcovrt"
  t.test_files = FileList['test/turn_off_rcovrt.rb', 'test/test*.rb']
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
  rdoc.rdoc_files.include('README.API')
  rdoc.rdoc_files.include('README.rake')
  rdoc.rdoc_files.include('README.rant')
  rdoc.rdoc_files.include('README.vim')
  rdoc.rdoc_files.include('lib/**/*.rb')
}

task :default => :test

desc "install by setup.rb"
task :install do
  sh "sudo ruby setup.rb install"
end

desc "update functional test"
task :update_functional_test do
  chdir "test"
  sh "ruby ../bin/rcov -I../lib:../ext/rcovrt -a -o expected_coverage sample_04.rb"
  sh "ruby ../bin/rcov -I../lib:../ext/rcovrt -o expected_coverage sample_04.rb"

end

# vim: set sw=2 ft=ruby:
