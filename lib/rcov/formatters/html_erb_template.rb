module Rcov
  module Formatters

    class HtmlErbTemplate
      attr_accessor :local_variables 

      def initialize(template_file, locals={})
        require "erb"

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

  end
end