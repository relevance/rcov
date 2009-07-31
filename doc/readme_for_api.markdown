# RCov

RCov is a:

1. tool for code coverage analysis for Ruby
2. library for collecting code coverage and execution count information introspectively

If you want to use the command line tool, the output from `rcov -h` is self explanatory.  If you want to automate the execution of RCov via Rake take a look at [readme for rake]("http://github.com/relevance/rcov/blob/master/doc/readme_for_rake.markdown").  If you want to use the associated library, read on.

## Usage of the RCov runtime/library

RCov is primarily a tool for code coverage analysis, but since 0.4.0 it exposes some of its code so that you can build on top of its heuristics for code analysis and its capabilities for coverage information and execution count gathering.  The main classes of interest are `Rcov::FileStatistics`, `Rcov::CodeCoverageAnalyzer` and `Rcov::CallSiteAnalyzer`. 

* `Rcov::FileStatistics` can use some heuristics to determine which parts of the file are executable and which are mere comments.

* `Rcov::CodeCoverageAnalyzer` is used to gather code coverage and execution count information inside a running Ruby program.

* `Rcov::CallSiteAnalyzer` is used to obtain information about where methods are defined and who calls them.

The parts of RCov's runtime meant to be reused (i.e. the external API) are documented with RDoc. Those not meant to be used are clearly marked as so or were deliberately removed from the present documentation.


