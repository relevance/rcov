#require 'rcov/xx'
require "erb"

class Document

  attr_accessor :local_variables 

  def initialize(template_file, locals={})
    template_path = File.expand_path("#{File.dirname(__FILE__)}/../templates/#{template_file}")
    @template = ERB.new(File.read(template_path))
    @local_variables = locals
    @path_relativizer = Hash.new{|h,base|
      # TODO: Waaaahhhhh?
      h[base] = Pathname.new(base).cleanpath.to_s.gsub(%r{^\w:[/\\]}, "").gsub(/\./, "_").gsub(/[\\\/]/, "-") + ".html"
    }
  end
  
  def render
    @template.result(get_binding)
  end

  def relative_filename(path)
    @path_relativizer[path]
  end

  #def create_cross_refs(filename, lineno, linetext)
    #form = formatter
    #return linetext unless @callsite_analyzer && @do_callsites

    #ref_blocks = []
    #form.send(:_get_defsites, ref_blocks, filename, lineno, "Calls", linetext) do |ref|
      #if ref.file
          #where = "at #{formatter.normalize_filename(ref.file)}:#{ref.line}"
      #else
          #where = "(C extension/core)"
      #end
      #CGI.escapeHTML("%7d   %s" % [ref.count, "#{ref.klass}##{ref.mid} " + where])
    #end

    #form.send(:_get_callsites, ref_blocks, filename, lineno, "Called by", linetext) do |ref|
      #r = "%7d   %s" % [ref.count, "#{formatter.normalize_filename(ref.file||'C code')}:#{ref.line} " + "in '#{ref.klass}##{ref.mid}'"]
      #CGI.escapeHTML(r)
    #end

    #create_cross_reference_block(linetext, ref_blocks)
  #end

  #def create_cross_reference_block(linetext, ref_blocks)
      #return linetext if ref_blocks.empty?
      #ret = ""
      #@cross_ref_idx ||= 0
      #@known_files ||= formatter.sorted_file_pairs.map{|fname, finfo| formatter.normalize_filename(fname)}
      #ret << %[<a class="crossref-toggle" href="#" onclick="toggleCode('XREF-#{@cross_ref_idx+=1}'); return false;">#{linetext}</a>]
      #ret << %[<span class="cross-ref" id="XREF-#{@cross_ref_idx}">]
      #ret << "\n"
      #ref_blocks.each do |refs, toplabel, label_proc|
          #unless !toplabel || toplabel.empty?
              #ret << %!<span class="cross-ref-title">#{toplabel}</span>\n!
          #end
          #refs.each do |dst|
              #dstfile = formatter.normalize_filename(dst.file) if dst.file
              #dstline = dst.line
              #label = label_proc.call(dst)
              #if dst.file && @known_files.include?(dstfile)
                  #ret << %[<a href="#{formatter.mangle_filename(dstfile)}#line#{dstline}">#{label}</a>]
              #else
                  #ret << label
              #end
              #ret << "\n"
          #end
      #end
      #ret << "</span>"
  #end

  def line_css(line_number)
    case file.coverage[line_number]
    when true
      "marked"
    when :inferred
      "inferred"
    else
      "uncovered"
    end
  end


 #def format_lines(file)
      #result = ""
      #last = nil
      #end_of_span = ""
      #format_line = "%#{file.num_lines.to_s.size}d"
      #file.num_lines.times do |i|
          #line = file.lines[i].chomp
          #marked = file.coverage[i]
          #count = file.counts[i]
          #spanclass = span_class(file, marked, count)
          #if spanclass != last
              #result += end_of_span
              #case spanclass
              #when nil
                  #end_of_span = ""
              #else
                  #result += %[<span class="#{spanclass}">]
                  #end_of_span = "</span>"
              #end
          #end
          #result += %[<a name="line#{i+1}"></a>] + (format_line % (i+1)) +
              #" " + create_cross_refs(file.name, i+1, CGI.escapeHTML(line)) + "\n"
          #last = spanclass
      #end
      #result += end_of_span
      #"<pre>#{result}</pre>"
  #end


  def method_missing(key, *args)
    local_variables.has_key?(key) ? local_variables[key] : super
  end

  def get_binding
    binding 
  end

end

module Rcov
  
  class BaseFormatter # :nodoc:
    require 'pathname'

    ignore_files = [/\A#{Regexp.escape(Pathname.new(::Config::CONFIG["libdir"]).cleanpath.to_s)}/,
                    /\btc_[^.]*.rb/, /_test\.rb\z/, /\btest\//, /\bvendor\//, /\A#{Regexp.escape(__FILE__)}\z/]

    DEFAULT_OPTS = {:ignore => ignore_files, :sort => :name, :sort_reverse => false,
      :output_threshold => 101, :dont_ignore => [], :callsite_analyzer => nil, :comments_run_by_default => false}

    def initialize(opts = {})
      options = DEFAULT_OPTS.clone.update(opts)
      @files = {}
      @ignore_files = options[:ignore]
      @dont_ignore_files = options[:dont_ignore]
      @sort_criterium = case options[:sort]
      when :loc then lambda{|fname, finfo| finfo.num_code_lines}
      when :coverage then lambda{|fname, finfo| finfo.code_coverage}
      else lambda{|fname, finfo| fname}
      end
      @sort_reverse = options[:sort_reverse]
      @output_threshold = options[:output_threshold]
      @callsite_analyzer = options[:callsite_analyzer]
      @comments_run_by_default = options[:comments_run_by_default]
      @callsite_index = nil

      @mangle_filename = Hash.new{|h,base|
        h[base] = Pathname.new(base).cleanpath.to_s.gsub(%r{^\w:[/\\]}, "").gsub(/\./, "_").gsub(/[\\\/]/, "-") + ".html"
      }
    end

    def add_file(filename, lines, coverage, counts)
      old_filename = filename
      filename = normalize_filename(filename)
      SCRIPT_LINES__[filename] = SCRIPT_LINES__[old_filename]
      if @ignore_files.any?{|x| x === filename} &&
        !@dont_ignore_files.any?{|x| x === filename}
        return nil
      end
      if @files[filename]
        @files[filename].merge(lines, coverage, counts)
      else
        @files[filename] = FileStatistics.new(filename, lines, counts,
        @comments_run_by_default)
      end
    end

    def normalize_filename(filename)
      File.expand_path(filename).gsub(/^#{Regexp.escape(Dir.getwd)}\//, '')
    end

    def mangle_filename(base)
      @mangle_filename[base]
    end

    def each_file_pair_sorted(&b)
      return sorted_file_pairs unless block_given?
      sorted_file_pairs.each(&b)
    end

    def sorted_file_pairs
      pairs = @files.sort_by do |fname, finfo|
        @sort_criterium.call(fname, finfo)
      end.select{|_, finfo| 100 * finfo.code_coverage < @output_threshold}
      @sort_reverse ? pairs.reverse : pairs
    end

    def total_coverage
      lines = 0
      total = 0.0
      @files.each do |k,f|
        total += f.num_lines * f.total_coverage
        lines += f.num_lines
      end
      return 0 if lines == 0
      total / lines
    end

    def code_coverage
      lines = 0
      total = 0.0
      @files.each do |k,f|
        total += f.num_code_lines * f.code_coverage
        lines += f.num_code_lines
      end
      return 0 if lines == 0
      total / lines
    end

    def num_code_lines
      lines = 0
      @files.each{|k, f| lines += f.num_code_lines }
      lines
    end

    def num_lines
      lines = 0
      @files.each{|k, f| lines += f.num_lines }
      lines
    end

    private
    def cross_references_for(filename, lineno)
      return nil unless @callsite_analyzer
      @callsite_index ||= build_callsite_index
      @callsite_index[normalize_filename(filename)][lineno]
    end

    def reverse_cross_references_for(filename, lineno)
      return nil unless @callsite_analyzer
      @callsite_reverse_index ||= build_reverse_callsite_index
      @callsite_reverse_index[normalize_filename(filename)][lineno]
    end

    def build_callsite_index
      index = Hash.new{|h,k| h[k] = {}}
      @callsite_analyzer.analyzed_classes.each do |classname|
        @callsite_analyzer.analyzed_methods(classname).each do |methname|
          defsite = @callsite_analyzer.defsite(classname, methname)
          index[normalize_filename(defsite.file)][defsite.line] =
          @callsite_analyzer.callsites(classname, methname)
        end
      end
      index
    end

    def build_reverse_callsite_index
      index = Hash.new{|h,k| h[k] = {}}
      @callsite_analyzer.analyzed_classes.each do |classname|
        @callsite_analyzer.analyzed_methods(classname).each do |methname|
          callsites = @callsite_analyzer.callsites(classname, methname)
          defsite = @callsite_analyzer.defsite(classname, methname)
          callsites.each_pair do |callsite, count|
            next unless callsite.file
            fname = normalize_filename(callsite.file)
            (index[fname][callsite.line] ||= []) << [classname, methname, defsite, count]
          end
        end
      end
      index
    end

    class XRefHelper < Struct.new(:file, :line, :klass, :mid, :count) # :nodoc:
    end

    def _get_defsites(ref_blocks, filename, lineno, linetext, label, &format_call_ref)
      if @do_cross_references and
        (rev_xref = reverse_cross_references_for(filename, lineno))
        refs = rev_xref.map do |classname, methodname, defsite, count|
          XRefHelper.new(defsite.file, defsite.line, classname, methodname, count)
        end.sort_by{|r| r.count}.reverse
        ref_blocks << [refs, label, format_call_ref]
      end
    end

    def _get_callsites(ref_blocks, filename, lineno, linetext, label, &format_called_ref)
      if @do_callsites and
        (refs = cross_references_for(filename, lineno))
        refs = refs.sort_by{|k,count| count}.map do |ref, count|
          XRefHelper.new(ref.file, ref.line, ref.calling_class, ref.calling_method, count)
        end.reverse
        ref_blocks << [refs, label, format_called_ref]
      end
    end

  end

end
