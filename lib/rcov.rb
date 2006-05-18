# rcov Copyright (c) 2004-2006 Mauricio Fernandez <mfp@acm.org>
#
# See LEGAL and LICENSE for licensing information.

require 'rcov/version'

SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__

module Rcov
    
class CoverageInfo
  def initialize(coverage_array)
    @cover = coverage_array.clone
  end

  def [](idx)
    @cover[idx]
  end

  def []=(idx, val)
    unless [true, false, :inferred].include? val
      raise RuntimeError, "What does #{val} mean?" 
    end
    return if idx < 0 || idx >= @cover.size
    @cover[idx] = val
  end

  def to_a
    @cover.clone
  end

  def method_missing(meth, *a, &b)
    @cover.send(meth, *a, &b)
  end
end

class SourceFile
  attr_reader :name, :lines, :coverage, :counts
  def initialize(name, lines, initial_coverage, counts)
    @name = name
    @lines = lines
    @coverage = CoverageInfo.new initial_coverage
    @counts = counts
    @is_begin_comment = nil
    # points to the line defining the heredoc identifier
    # but only if it was marked (we don't care otherwise)
    @heredoc_start = Array.new(lines.size, false)
    extend_heredocs
    precompute_coverage false
  end

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

  def total_coverage
    return 0 if @coverage.size == 0
    @coverage.inject(0.0) {|s,a| s + (a ? 1:0) } / @coverage.size
  end

  def code_coverage
    indices = (0...@lines.size).select{|i| is_code? i }
    return 0 if indices.size == 0
    count = 0
    indices.each {|i| count += 1 if @coverage[i] }
    1.0 * count / indices.size
  end

  def num_code_lines
    (0...@lines.size).select{|i| is_code? i}.size
  end

  def num_lines
    @lines.size
  end

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
        /^\s*(\)|\]|\})(?:#.*)?$/ =~ line && prev_expr_marked?(i) or
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
    #FIXME: / matches regexps too
    r = /(,|\.|\+|-|\*|\/|<|>|%|&&|\|\||<<|\(|\[|\{|=|and|or)\s*(?:#.*)?$/.match @lines[idx]
    if /(do|\{)\s*\|.*\|\s*(?:#.*)?$/.match @lines[idx]
      return false
    end
    r
  end
end


autoload :RCOV__, "rcov/lowlevel.rb"

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

  def analyzed_files
    raw_data_relative.select do |file, lines|
      @script_lines__.has_key?(file)
    end.map{|fname,| fname}
  end

  def data(filename)
    unless @script_lines__.has_key?(filename) && 
           raw_data_relative.has_key?(filename)
      return nil 
    end
    refine_coverage_info(@script_lines__[filename], raw_data_relative[filename])
  end

  def run_hooked
    install_hook
    yield
  ensure
    remove_hook
  end

  def install_hook
    @start_raw_data = raw_data_absolute
    Rcov::RCOV__.install_hook
    @cache_state = :hooked
    @@mutex.synchronize{ @@hook_level += 1 }
  end

  def remove_hook
    @@mutex.synchronize do 
      @@hook_level -= 1
      Rcov::RCOV__.remove_hook if @@hook_level == 0
    end
    @end_raw_data = raw_data_absolute
    @cache_state = :done
    raw_data_relative
  end

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

  def dump_coverage_info(formatters)
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
