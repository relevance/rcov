# Code coverage analysis automation with Rake

Since 0.4.0, RCov features a `Rcov::RcovTask` task for rake
which can be used to automate test coverage analysis.  Basic usage is as
follows:
<pre><code>
require 'rcov/rcovtask'
Rcov::RcovTask.new do |t|
  t.test_files = FileList['test/test*.rb']
  # t.verbose = true     # uncomment to see the executed command
end
</pre></code>

This will create by default a task named `rcov`, and also a task to remove the output directory where the XHTML report is generated.  The latter will be named `clobber_rcov`, and will be added to the main `clobber` target.

## Passing command line options to RCov

You can provide a description, change the name of the generated tasks (the one used to generate the report(s) and the `clobber_` one) and pass options to RCov:
<pre><code>
desc "Analyze code coverage of the unit tests."
Rcov::RcovTask.new(:coverage) do |t|
  t.test_files = FileList['test/test*.rb']
  t.verbose = true
  ## get a text report on stdout when rake is run:
  t.rcov_opts << "--text-report"  
  ## only report files under 80% coverage
  t.rcov_opts << "--threshold 80"
end
</pre></code>

This will generate a `coverage` task and the associated `clobber_coverage` task to remove the directory the report is dumped to (`coverage` by default).  You can specify a different destination directory, which comes handy if you have several `RcovTask`s; the `clobber_*` will take care of removing that directory:
<pre><code>
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
</pre></code>

## Options passed through the `rake` command line

You can override the options defined in the RcovTask by passing the new options at the time you invoke rake. The documentation for the `Rcov::RcovTask` explains how this can be done.
