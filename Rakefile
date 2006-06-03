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
  t.libs << "ext/rcovrt"
  t.test_files = FileList['test/test*.rb']
  t.rcov_opts << "--xrefs"  # comment to disable cross-references
  t.verbose = true
end

desc "Analyze code coverage for the FileStatistics class."
Rcov::RcovTask.new(:rcov_sourcefile) do |t|
  t.libs << "ext/rcovrt"
  t.test_files = FileList['test/test_FileStatistics.rb']
  t.verbose = true
  t.rcov_opts << "--test-unit-only"
  t.output_dir = "coverage.sourcefile"
end

Rcov::RcovTask.new(:rcov_ccanalyzer) do |t|
  t.libs << "ext/rcovrt"
  t.test_files = FileList['test/test_CodeCoverageAnalyzer.rb']
  t.verbose = true
  t.rcov_opts << "--test-unit-only"
  t.output_dir = "coverage.ccanalyzer"
end

desc "Run the unit tests with rcovrt."
Rake::TestTask.new(:test_rcovrt => ["ext/rcovrt/rcovrt.so"]) do |t|
  t.libs << "ext/rcovrt"
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

file "ext/rcovrt/rcovrt.so" => "ext/rcovrt/rcov.c" do
  ruby "setup.rb config"
  ruby "setup.rb setup"
end

desc "Run the unit tests in pure-Ruby mode ."
Rake::TestTask.new(:test_pure_ruby) do |t|
  t.libs << "ext/rcovrt"
  t.test_files = FileList['test/turn_off_rcovrt.rb', 'test/test*.rb']
  t.verbose = true
end

desc "Run the unit tests, both rcovrt and pure-Ruby modes"
task :test => [:test_rcovrt, :test_pure_ruby]

desc "Generate rdoc documentation for the rcov library"
Rake::RDocTask.new("rdoc") { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "rcov"
  rdoc.options << "--line-numbers" << "--inline-source"
  rdoc.rdoc_files.include('README.API')
  rdoc.rdoc_files.include('README.rake')
  rdoc.rdoc_files.include('README.rant')
  rdoc.rdoc_files.include('lib/**/*.rb')
}

task :default => :test

# vim: set sw=2 ft=ruby:
