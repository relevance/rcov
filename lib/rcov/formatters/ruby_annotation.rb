module Rcov
  module Formatters
    class RubyAnnotation < BaseFormatter
      DEFAULT_OPTS = { :destdir => "coverage" }

      def initialize(opts = {})
        options = DEFAULT_OPTS.clone.update(opts)
        super(options)
        @dest = options[:destdir]
        @do_callsites = true
        @do_cross_references = true
        @mangle_filename = Hash.new{|h,base|
          h[base] = Pathname.new(base).cleanpath.to_s.gsub(%r{^\w:[/\\]}, "").gsub(/\./, "_").gsub(/[\\\/]/, "-") + ".rb"
        }
      end

      def execute
        return if @files.empty?
        FileUtils.mkdir_p @dest
        each_file_pair_sorted do |filename, fileinfo|
          create_file(File.join(@dest, mangle_filename(filename)), fileinfo)
        end
      end

      private

      def format_lines(file)
        result = ""
        format_line = "%#{file.num_lines.to_s.size}d"
        file.num_lines.times do |i|
          line = file.lines[i].chomp
          marked = file.coverage[i]
          count = file.counts[i]
          result << create_cross_refs(file.name, i+1, line, marked) + "\n"
        end
        result
      end

      def create_cross_refs(filename, lineno, linetext, marked)
        return linetext unless @callsite_analyzer && @do_callsites
        ref_blocks = []
        _get_defsites(ref_blocks, filename, lineno, linetext, ">>") do |ref|
          if ref.file
            ref.file.sub!(%r!^./!, '')
            where = "at #{mangle_filename(ref.file)}:#{ref.line}"
          else
            where = "(C extension/core)"
          end
          "#{ref.klass}##{ref.mid} " + where + ""
        end
        _get_callsites(ref_blocks, filename, lineno, linetext, "<<") do |ref| # "
          ref.file.sub!(%r!^./!, '')
          "#{mangle_filename(ref.file||'C code')}:#{ref.line} " +
          "in #{ref.klass}##{ref.mid}"
        end

        create_cross_reference_block(linetext, ref_blocks, marked)
      end

      def create_cross_reference_block(linetext, ref_blocks, marked)
        codelen = 75
        if ref_blocks.empty?
          if marked
            return "%-#{codelen}s #o" % linetext
          else
            return linetext
          end
        end
        ret = ""
        @cross_ref_idx ||= 0
        @known_files ||= sorted_file_pairs.map{|fname, finfo| normalize_filename(fname)}
        ret << "%-#{codelen}s # " % linetext
        ref_blocks.each do |refs, toplabel, label_proc|
          unless !toplabel || toplabel.empty?
            ret << toplabel << " "
          end
          refs.each do |dst|
            dstfile = normalize_filename(dst.file) if dst.file
            dstline = dst.line
            label = label_proc.call(dst)
            if dst.file && @known_files.include?(dstfile)
              ret << "[[" << label << "]], "
            else
              ret << label << ", "
            end
          end
        end

        ret
      end

      def create_file(destfile, fileinfo)
        #body = format_lines(fileinfo)
        #File.open(destfile, "w") do |f|
        #f.puts body
        #f.puts footer(fileinfo)
        #end
      end

      def footer(fileinfo)
        s  = "# Total lines    : %d\n" % fileinfo.num_lines
        s << "# Lines of code  : %d\n" % fileinfo.num_code_lines
        s << "# Total coverage : %3.1f%%\n" % [ fileinfo.total_coverage*100 ]
        s << "# Code coverage  : %3.1f%%\n\n" % [ fileinfo.code_coverage*100 ]
        # prevents false positives on Emacs
        s << "# Local " "Variables:\n" "# mode: " "rcov-xref\n" "# End:\n"
      end
    end
  end
end