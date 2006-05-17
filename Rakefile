# This Rakefile serves as an example of how to use Rcov::RcovTask.
# Take a look at the RDoc documentation (or README.rake) for further
# information.

$:.unshift "lib" if File.directory? "lib"
require 'rcov/rcovtask'
require 'rake/testtask'
require 'rake/rdoctask'

desc "Analyze code coverage of the unit tests."
Rcov::RcovTask.new do |t|
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
  t.rcov_opts << "--text-report"
  t.rcov_opts << "--threshold 80"
end

desc "Analyze code coverage for the SourceFile class."
Rcov::RcovTask.new(:rcov_sourcefile) do |t|
  t.test_files = FileList['test/test_SourceFile.rb']
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
  rdoc.rdoc_files.include('README.rake')
  rdoc.rdoc_files.include('lib/**/*.rb')
}


task :default => :test

# vim: set sw=2 ft=ruby:
