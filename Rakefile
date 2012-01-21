require 'rake/testtask'
require 'rake/clean'
require 'rcov/rcovtask'
require 'rcov/version'

desc "Run the unit tests with rcovrt."
Rake::TestTask.new(:test_rcovrt) do |t|
  system("cd ext/rcovrt && make clean && rm Makefile")
  system("cd ext/rcovrt && ruby extconf.rb && make")
  t.libs << "ext/rcovrt"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

task :default => [:test_rcovrt]
