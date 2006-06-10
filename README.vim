
rcov.vim allows you to run test unit tests from vim and enter quickfix mode in
order to jump to uncovered code introduced since the last run.

Installation
============
Copy rcov.vim to the appropriate "compiler" directory (typically
$HOME/.vim/compiler).

Usage
=====

Setting the reference point
---------------------------
rcov's --text-coverage-diff mode compares the current coverage status against
a previously stored one. It therefore needs that information to be saved
before you write new code (typically right after you perform a commit) in
order to have something to compare against.

You can save the current status with the --save option.
If you're running rcov from Rake, you can do something like
  rake rcov_units RCOVOPTS="-T --save --rails"
in order to take the current status as the reference point.

Comparing with a recorded coverage status
-----------------------------------------
Type the following in command mode while editing your program:
   :compiler rcov

rcov.vim assumes rcov can be invoked with a rake task (see README.rake for
information on how to create it). 

You can then execute rcov and enter quickfix mode by typing

   :make <taskname>

where taskname is the rcov task you want to use; if you didn't override the
default name in the Rakefile, just
  
   :make rcov

will do.

vim will then enter quickfix mode, allowing you to jump to the areas that were
not covered since the last time you saved the coverage data.

