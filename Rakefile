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

desc "Analyze code coverage of the unit tests."
Rcov::RcovTask.new do |t|
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
  t.rcov_opts << "--text-report"
end

desc "Analyze code coverage for the FileStatistics class."
Rcov::RcovTask.new(:rcov_sourcefile) do |t|
  t.test_files = FileList['test/test_FileStatistics.rb']
  t.verbose = true
  t.rcov_opts << "--test-unit-only"
  t.output_dir = "coverage.sourcefile"
end

Rcov::RcovTask.new(:rcov_ccanalyzer) do |t|
  t.test_files = FileList['test/test_CodeCoverageAnalyzer.rb']
  t.verbose = true
  t.rcov_opts << "--test-unit-only"
  t.output_dir = "coverage.ccanalyzer"
end

desc "Run the unit tests."
Rake::TestTask.new do |t|
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
end

desc "Generate rdoc documentation for the rcov library"
Rake::RDocTask.new("rdoc") { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "rcov task for rake"
  rdoc.options << "--line-numbers" << "--inline-source"
  rdoc.rdoc_files.include('README.API')
  rdoc.rdoc_files.include('README.rake')
  rdoc.rdoc_files.include('lib/**/*.rb')
}


task :default => :test

# vim: set sw=2 ft=ruby:
