
<tt>rcov.el</tt> allows you to use rcov from Emacs conveniently.
* Run unit tests and navigate uncovered code by <tt>C-x `</tt>.
* View cross-reference annotated code.

== Installation

Copy <tt>rcov.el</tt> to the appropriate directory, which is in load-path.

== Usage

=== Finding uncovered code

<tt>M-x rcov</tt> runs
  "rake rcov RCOVOPTS='--gcc'"
in other window by default.
The +rcov+ window is compilation-mode, so you can navigate uncovered code by <tt>C-x `</tt>.
If you do not use +rcov+ from Rake, you must modify +rcov-command-line+ variable.

=== Viewing cross-reference annotated code

If you read cross-reference annotated code, issue
  rake rcov RCOVOPTS='-a'
at the beginning.
This command creates +coverage+ directory and many *.rb files in it.
Filenames of these Ruby scripts are converted from original path.
You can browse them by normally <tt>C-x C-f</tt>.
You can think of <tt>-a</tt> option as <tt>--xrefs</tt> option and output format is Ruby script.

After find-file-ed annotated script, the major-mode is rcov-xref-mode,
which is derived from ruby-mode and specializes navigation.

<tt>Tab</tt> and <tt>M-Tab</tt> goes forward/backward links.
<tt>Ret</tt> follows selected link.
