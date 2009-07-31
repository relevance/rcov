# rcov.vim

`rcov.vim` allows you to run unit tests from vim and enter quickfix mode in order to jump to uncovered code introduced since the last run.

## Installation
Copy `rcov.vim` to the appropriate `compiler` directory (typically `$HOME/.vim/compiler`).

### Usage

#### Setting the reference point

RCov's `--text-coverage-diff` mode compares the current coverage status against the saved one. It therefore needs that information to be recorded before you write new code (typically right after you perform a commit) in order to have something to compare against.  You can save the current status with the `--save` option.  If you're running RCov from Rake, you can do something like
  
`rake rcov_units RCOVOPTS="-T --save --rails"`

in order to take the current status as the reference point.

#### Finding new uncovered code

Type the following in command mode while editing your program:
  
`:compiler rcov`

`rcov.vim` assumes RCov can be invoked with a rake task (see  [readme for rake]("http://github.com/relevance/rcov/blob/master/doc/readme_for_rake.markdown") for information on how to create it). 

You can then execute +rcov+ and enter quickfix mode by typing

`:make <taskname>`

where taskname is the +rcov+ task you want to use; if you didn't override the default name in the Rakefile, just
  
`:make rcov`

will do.  Vim will then enter quickfix mode, allowing you to jump to the areas that were not covered since the last time you saved the coverage data.
