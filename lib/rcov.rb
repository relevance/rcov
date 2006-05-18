# rcov Copyright (c) 2004-2006 Mauricio Fernandez <mfp@acm.org>
#
# See LEGAL and LICENSE for licensing information.

require 'rcov/version'

SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__

module Rcov
    
# Rcov::CoverageInfo is but a wrapper for an array, with some additional
# checks. It is returned by SourceFile#coverage.
class CoverageInfo
  def initialize(coverage_array)
    @cover = coverage_array.clone
  end

# Return the coverage status for the requested line. There are four possible
# return values:
# * nil if there's no information for the requested line (i.e. it doesn't exist)
# * true if the line was reported by Ruby as executed
# * :inferred if rcov inferred it was executed, despite not being reported 
#   by Ruby.
# * false otherwise, i.e. if it was not reported by Ruby and rcov's
#   heuristics indicated that it was not executed
  def [](line)
    @cover[line]
  end

  def []=(line, val) # :nodoc:
    unless [true, false, :inferred].include? val
      raise RuntimeError, "What does #{val} mean?" 
    end
    return if line < 0 || line >= @cover.size
    @cover[line] = val
  end

# Return an Array holding the code coverage information.
  def to_a
    @cover.clone
  end

  def method_missing(meth, *a, &b) # :nodoc:
    @cover.send(meth, *a, &b)
  end
end

# A SourceFile object associates a filename to:
# 1. its source code
# 2. the per-line coverage information after correction using rcov's heuristics
# 3. the per-line execution counts
#
# A SourceFile object can be therefore be built given the filename, the
# associated source code, and an array holding execution counts (i.e. how many
# times each line has been executed).
#
# SourceFile is relatively intelligent: it handles normal comments,
# <tt>=begin/=end</tt>, heredocs, many multiline-expressions... It uses a
# number of heuristics to determine what is code and what is a comment, and to
# refine the initial (incomplete) coverage information.
#
# Basic usage is as follows:
#  sf = SourceFile.new("foo.rb", ["puts 1", "if true &&", "   false", 
#                                 "puts 2", "end"],  [1, 1, 0, 0, 0])
#  sf.num_lines        # => 5
#  sf.num_code_lines   # => 5
#  sf.coverage[2]      # => true
#  sf.coverage[3]      # => :inferred
#  sf.code_coverage    # => 0.6
#                    
# The array of strings representing the source code and the array of execution
# counts would normally be obtained from a Rcov::CodeCoverageAnalyzer.
class SourceFile
  attr_reader :name, :lines, :coverage, :counts
  def initialize(name, lines, counts)
    @name = name
    @lines = lines
    initial_coverage = counts.map{|x| (x || 0) > 0 ? true : false }
    @coverage = CoverageInfo.new initial_coverage
    @counts = counts
    @is_begin_comment = nil
    # points to the line defining the heredoc identifier
    # but only if it was marked (we don't care otherwise)
    @heredoc_start = Array.new(lines.size, false)
    extend_heredocs
    precompute_coverage false
  end

  # Merge code coverage and execution count information.
  # As for code coverage, a line will be considered
  # * covered for sure (true) if it is covered in either +self+ or in the 
  #   +coverage+ array
  # * considered <tt>:inferred</tt> if the neither +self+ nor the +coverage+ array
  #   indicate that it was definitely executed, but it was <tt>inferred</tt>
  #   in either one 
  # * not covered (<tt>false</tt>) if it was uncovered in both
  #
  # Execution counts are just summated on a per-line basis.
  def merge(lines, coverage, counts)
    coverage.each_with_index do |v, idx|
      case @coverage[idx]
      when :inferred : @coverage[idx] = v || @coverage[idx]
      when false : @coverage[idx] ||= v
      end
    end
    counts.each_with_index{|v, idx| @counts[idx] += v }
    precompute_coverage false
  end

  # Total coverage rate if comments are also considered "executable", given as
  # a fraction, i.e. from 0 to 1.0.
  # A comment is attached to the code following it (RDoc-style): it will be
  # considered executed if the the next statement was executed.
  def total_coverage
    return 0 if @coverage.size == 0
    @coverage.inject(0.0) {|s,a| s + (a ? 1:0) } / @coverage.size
  end

  # Code coverage rate: fraction of lines of code executed, relative to the
  # total amount of lines of code (loc). Returns a float from 0 to 1.0.
  def code_coverage
    indices = (0...@lines.size).select{|i| is_code? i }
    return 0 if indices.size == 0
    count = 0
    indices.each {|i| count += 1 if @coverage[i] }
    1.0 * count / indices.size
  end
  
  # Number of lines of code (loc).
  def num_code_lines
    (0...@lines.size).select{|i| is_code? i}.size
  end

  # Total number of lines.
  def num_lines
    @lines.size
  end

  # Returns true if the given line number corresponds to code, as opposed to a
  # comment (either # or =begin/=end blocks).
  def is_code?(lineno)
    unless @is_begin_comment
      @is_begin_comment = Array.new(@lines.size, false)
      pending = []
      state = :code
      @lines.each_with_index do |line, index|
        case state
        when :code
          if /^=begin\b/ =~ line
            state = :comment
            pending << index
          end
        when :comment
          pending << index
          if /^=end\b/ =~ line
            state = :code
            pending.each{|idx| @is_begin_comment[idx] = true}
            pending.clear
          end
        end
      end
    end
    @lines[lineno] && !@is_begin_comment[lineno] && 
      @lines[lineno] !~ /^\s*(#|$)/ 
  end

  private

  def precompute_coverage(comments_run_by_default = true)
    changed = false
    (0...lines.size).each do |i|
      next if @coverage[i]
      line = @lines[i]
      if /^\s*(begin|ensure|else|case)\s*(?:#.*)?$/ =~ line && next_expr_marked?(i) or
        /^\s*(?:end|\})\s*(?:#.*)?$/ =~ line && prev_expr_marked?(i) or
        /^\s*rescue\b/ =~ line && next_expr_marked?(i) or
        prev_expr_continued?(i) && prev_expr_marked?(i) or
        comments_run_by_default && !is_code?(i) or 
        /^\s*((\)|\]|\})\s*)+(?:#.*)?$/ =~ line && prev_expr_marked?(i) or
        prev_expr_continued?(i+1) && next_expr_marked?(i)
        @coverage[i] ||= :inferred
        changed = true
      end
    end
    (@lines.size-1).downto(0) do |i|
      next if @coverage[i]
      if !is_code?(i) and @coverage[i+1] 
        @coverage[i] = :inferred
        changed = true
      end
    end

    extend_heredocs if changed

    # if there was any change, we have to recompute; we'll eventually
    # reach a fixed point and stop there
    precompute_coverage(comments_run_by_default) if changed
  end

  require 'strscan'
  def extend_heredocs
    i = 0
    while i < @lines.size
      unless is_code? i
        i += 1
        next
      end
      #FIXME: using a restrictive regexp so that only <<[A-Z_a-z]\w*
      # matches when unquoted, so as to avoid problems with 1<<2
      # (keep in mind that whereas puts <<2 is valid, puts 1<<2 is a
      # parse error, but  a = 1<<2  is of course fine)
      scanner = StringScanner.new(@lines[i])
      j = k = i
      loop do
        scanned_text = scanner.search_full(/<<(-?)(?:(['"`])((?:(?!\2).)+)\2|([A-Z_a-z]\w*))/, 
                                           true, true)
        unless scanner.matched?
          i = k
          break
        end
        term = scanner[3] || scanner[4]
        # try to ignore symbolic bitshifts like  1<<LSHIFT
        ident_text = "<<#{scanner[1]}#{scanner[2]}#{term}#{scanner[2]}"
        if scanned_text[/\d+\s*#{Regexp.escape(ident_text)}/]
          # it was preceded by a number, ignore
          i = k
          break
        end
        if @coverage[i]
          must_mark = []
          end_of_heredoc = (scanner[1] == "-") ? /^\s*#{Regexp.escape(term)}$/ :
            /^#{Regexp.escape(term)}$/
            loop do
            break if j == @lines.size
            must_mark << j
            if end_of_heredoc =~ @lines[j]
              must_mark.each do |n|
                @heredoc_start[n] = i
                @coverage[n] ||= :inferred
              end
              k = (j += 1)
              break
            end
            j += 1
            end
        end
      end

      i += 1
    end
  end

  def next_expr_marked?(lineno)
    return false if lineno >= @lines.size
    found = false
    idx = (lineno+1).upto(@lines.size-1) do |i|
      next unless is_code? i
      found = true
      break i
    end
    return false unless found
    @coverage[idx]
  end

  def prev_expr_marked?(lineno)
    return false if lineno <= 0
    found = false
    idx = (lineno-1).downto(0) do |i|
      next unless is_code? i
      found = true
      break i
    end
    return false unless found
    @coverage[idx]
  end

  def prev_expr_continued?(lineno)
    return false if lineno <= 0
    return false if lineno >= @lines.size
    found = false
    idx = (lineno-1).downto(0) do |i|
      if @heredoc_start[i]
        found = true
        break @heredoc_start[i] 
      end
      next unless is_code? i
      found = true
      break i
    end
    return false unless found
    #TODO: write a comprehensive list
    if is_code?(lineno) && /^\s*((\)|\]|\})\s*)+(?:#.*)?$/.match(@lines[lineno])
      return true
    end
    #FIXME: / matches regexps too
    r = /(,|\.|\+|-|\*|\/|<|>|%|&&|\|\||<<|\(|\[|\{|=|and|or)\s*(?:#.*)?$/.match @lines[idx]
    if /(do|\{)\s*\|.*\|\s*(?:#.*)?$/.match @lines[idx]
      return false
    end
    r
  end
end


autoload :RCOV__, "rcov/lowlevel.rb"

# A CodeCoverageAnalyzer is responsible for tracing code execution and
# returning code coverage and execution count information.
#
#  analyzer = Rcov::CodeCoverageAnalyzer.new
#  analyzer.run_hooked do 
#    do_foo  
#    # all the code executed as a result of this method call is traced
#  end
#  # ....
#  
#  analyzer.run_hooked do 
#    do_bar
#    # the code coverage information generated in this run is aggregated
#    # to the previously recorded one
#  end
#
#  analyzer.analyzed_files   # => ["foo.rb", "bar.rb", ... ]
#  lines, marked_info, count_info = analyzer.data("foo.rb")
#
# In this example, two pieces of code are monitored, and the data generated in
# both runs are aggregated. +lines+ is an array of strings representing the 
# source code of <tt>foo.rb</tt>. +marked_info+ is an array holding false,
# true values indicating whether the corresponding lines of code were reported
# as executed by Ruby. +count_info+ is an array of integers representing how
# many times each line of code has been executed (more precisely, how many
# events where reported by Ruby --- a single line might correspond to several
# events, e.g. many method calls).
#
# You can have several CodeCoverageAnalyzer objects at a time, and it is
# possible to nest the #run_hooked / #install_hook/#remove_hook blocks: each
# analyzer will manage its data separately. Note however that no special
# provision is taken to ignore code executed "inside" the CodeCoverageAnalyzer
# class. At any rate this will not pose a problem since it's easy to ignore it
# manually: just don't do
#   lines, coverage, counts = analyzer.data("/path/to/lib/rcov.rb")
# if you're not interested in that information.
class CodeCoverageAnalyzer
  @@hook_level = 0
  require 'thread'
  @@mutex = Mutex.new
  
  def initialize
    @script_lines__ = SCRIPT_LINES__
    @cache_state = :wait
    @start_raw_data = {}
    @end_raw_data = {}
    @aggregated_data = {}
  end
  
  # Return an array with the names of the files whose code was executed inside
  # the block given to #run_hooked or between #install_hook and #remove_hook.
  def analyzed_files
    raw_data_relative.select do |file, lines|
      @script_lines__.has_key?(file)
    end.map{|fname,| fname}
  end

  # Return the available data about the requested file, or nil if none of its
  # code was executed or it cannot be found.
  # The return value is an array with three elements:
  #  lines, marked_info, count_info = analyzer.data("foo.rb")
  # +lines+ is an array of strings representing the 
  # source code of <tt>foo.rb</tt>. +marked_info+ is an array holding false,
  # true values indicating whether the corresponding lines of code were reported
  # as executed by Ruby. +count_info+ is an array of integers representing how
  # many times each line of code has been executed (more precisely, how many
  # events where reported by Ruby --- a single line might correspond to several
  # events, e.g. many method calls).
  #
  # The returned data corresponds to the aggregation of all the statistics
  # collected in each #run_hooked or #install_hook/#remove_hook runs. You can
  # reset the data at any time with #reset to start from scratch.
  def data(filename)
    unless @script_lines__.has_key?(filename) && 
           raw_data_relative.has_key?(filename)
      return nil 
    end
    refine_coverage_info(@script_lines__[filename], raw_data_relative[filename])
  end

  # Execute the code in the given block, monitoring it in order to gather
  # information about which code was executed.
  def run_hooked
    install_hook
    yield
  ensure
    remove_hook
  end

  # Start monitoring execution to gather code coverage and execution count
  # information. Such data will be collected until #remove_hook is called.
  #
  # Use #run_hooked instead if possible.
  def install_hook
    @start_raw_data = raw_data_absolute
    Rcov::RCOV__.install_hook
    @cache_state = :hooked
    @@mutex.synchronize{ @@hook_level += 1 }
  end

  # Stop collecting code coverage and execution count information.
  # #remove_hook will also stop collecting info if it is run inside a
  # #run_hooked block.
  def remove_hook
    @@mutex.synchronize do 
      @@hook_level -= 1
      Rcov::RCOV__.remove_hook if @@hook_level == 0
    end
    @end_raw_data = raw_data_absolute
    @cache_state = :done
    raw_data_relative
  end

  # Remove the data collected so far. The coverage and execution count
  # "history" will be erased, and further collection will start from scratch:
  # no code is considered executed, and therefore all execution counts are 0.
  # Right after #reset, #analyzed_files will return an empty array, and
  # #data(filename) will return nil.
  def reset
    @@mutex.synchronize do
      if @@hook_level == 0
        Rcov::RCOV__.reset
        @start_raw_data = @end_raw_data = {}
      else
        @start_raw_data = @end_raw_data = raw_data_absolute
      end
      @raw_data_relative = {}
      @aggregated_data = {}
    end
  end

  def dump_coverage_info(formatters) # :nodoc:
    raw_data_relative.each do |file, lines|
      next if @script_lines__.has_key?(file) == false
      lines = @script_lines__[file]
      raw_coverage_array = raw_data_relative[file]

      line_info, marked_info, 
        count_info = refine_coverage_info(lines, raw_coverage_array)
      formatters.each do |formatter|
        formatter.add_file(file, line_info, marked_info, count_info)
      end
    end
    formatters.each{|formatter| formatter.execute}
  end

  private

  def raw_data_absolute
    Rcov::RCOV__.generate_coverage_info
  end

  def raw_data_relative
    case @cache_state
    when :wait
      return @aggregated_data
    when :hooked
      new_diff = compute_raw_data_difference(@start_raw_data, 
                                                       raw_data_absolute)
    when :done
      @cache_state = :wait
      new_diff = compute_raw_data_difference(@start_raw_data, 
                                             @end_raw_data)
    end

    new_diff.each_pair do |file, cov_arr|
      dest = (@aggregated_data[file] ||= Array.new(cov_arr.size, 0))
      cov_arr.each_with_index{|x,i| dest[i] += x}
    end

    @aggregated_data
  end

  def compute_raw_data_difference(first, last)
    difference = {}
    last.each_pair do |fname, cov_arr|
      unless first.has_key?(fname)
        difference[fname] = cov_arr.clone
      else
        orig_arr = first[fname]
        diff_arr = Array.new(cov_arr.size, 0)
        changed = false
        cov_arr.each_with_index do |x, i|
          diff_arr[i] = diff = (x || 0) - (orig_arr[i] || 0)
          changed = true if diff != 0
        end
        difference[fname] = diff_arr if changed
      end
    end
    difference
  end


  def refine_coverage_info(lines, covers)
    line_info = []
    marked_info = []
    count_info = []
    0.upto(lines.size - 1) do |c|
      line = lines[c].chomp
      marked = false
      marked = true if covers[c] && covers[c] > 0
      line_info << line
      marked_info << marked
      count_info << (covers[c] || 0)
    end

    [line_info, marked_info, count_info]
  end
end # CodeCoverageAnalyzer

end # Rcov

# vi: set sw=2:
