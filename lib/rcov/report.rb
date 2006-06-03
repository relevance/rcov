# rcov Copyright (c) 2004-2006 Mauricio Fernandez <mfp@acm.org>
# See LEGAL and LICENSE for additional licensing information.

module Rcov

class Formatter
    ignore_files = [/\A#{Regexp.escape(Config::CONFIG["libdir"])}/, /\btc_[^.]*.rb/,
        /_test\.rb\z/, /\btest\//, /\bvendor\//, /\A#{Regexp.escape(__FILE__)}\z/]
    DEFAULT_OPTS = {:ignore => ignore_files, :sort => :name, :sort_reverse => false,
                    :output_threshold => 101, :dont_ignore => [], 
                    :callsite_analyzer => nil}
    def initialize(opts = {})
        options = DEFAULT_OPTS.clone.update(opts)
        @files = {}
        @ignore_files = options[:ignore]
        @dont_ignore_files = options[:dont_ignore]
        @sort_criterium = case options[:sort]
            when :loc : lambda{|fname, finfo| finfo.num_code_lines}
            when :coverage : lambda{|fname, finfo| finfo.code_coverage}
            else lambda{|fname, finfo| fname}
        end
        @sort_reverse = options[:sort_reverse]
        @output_threshold = options[:output_threshold]
        @callsite_analyzer = options[:callsite_analyzer]
        @callsite_index = nil
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
            @files[filename] = FileStatistics.new filename, lines, counts
        end
    end

    def normalize_filename(filename)
        File.expand_path(filename).gsub(/^#{Regexp.escape(Dir.getwd)}\//, '')
    end

    def mangle_filename(base)
        base.gsub(%r{^\w:[/\\]}, "").gsub(/\./, "_").gsub(/[\\\/]/, "-") + ".html"
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
                callsites.each_key do |callsite|
                    next unless callsite.file
                    fname = normalize_filename(callsite.file)
                    (index[fname][callsite.line] ||= []) << [classname, methname, defsite]
                end
            end
        end
        index
    end
end

class TextSummary < Formatter
    def execute
        puts summary
    end

    def summary
        "%.1f%%   %d file(s)   %d Lines   %d LOC" % [code_coverage * 100,
            @files.size, num_lines, num_code_lines]
    end
end

class TextReport < TextSummary
    def execute
        print_lines
        print_header
        print_lines
        each_file_pair_sorted do |fname, finfo|
            name = fname.size < 52 ? fname : "..." + fname[-48..-1]
            print_info(name, finfo.num_lines, finfo.num_code_lines, 
                       finfo.code_coverage)
        end
        print_lines
        print_info("Total", num_lines, num_code_lines, code_coverage)
        print_lines
        puts summary
    end

    def print_info(name, lines, loc, coverage)
        puts "|%-51s | %5d | %5d | %5.1f%% |" % [name, lines, loc, 100 * coverage]
    end

    def print_lines
        puts "+----------------------------------------------------+-------+-------+--------+"
    end

    def print_header
        puts "|                  File                              | Lines |  LOC  |  COV   |"
    end
end

class FullTextReport < Formatter
    DEFAULT_OPTS = {:textmode => :coverage}
    def initialize(opts = {})
        options = DEFAULT_OPTS.clone.update(opts)
        @textmode = options[:textmode]
        @color = options[:color]
        super(options)
    end

    def execute
        each_file_pair_sorted do |filename, fileinfo|
            puts "=" * 80
            puts filename
            puts "=" * 80
            SCRIPT_LINES__[filename].each_with_index do |line, i|
                case @textmode
                when :counts
                    puts "%-70s| %6d" % [line.chomp[0,70], fileinfo.counts[i]]
                when :coverage
                    if @color
                        prefix = fileinfo.coverage[i] ? "\e[32;40m" : "\e[31;40m"
                        puts "#{prefix}%s\e[37;40m" % line.chomp
                    else
                        prefix = fileinfo.coverage[i] ? "   " : "!! "
                        puts "#{prefix}#{line}"
                    end
                end
            end
        end
    end
end

class TextCoverageDiff < Formatter
    DEFAULT_OPTS = {:textmode => :coverage_diff, 
                    :coverage_diff_mode => :record,
                    :coverage_diff_file => "coverage.info",
                    :diff_cmd => "diff"}
    def SERIALIZER
        # mfp> this was going to be YAML but I caught it failing at basic
        # round-tripping, turning "\n" into "" and corrupting the data, so
        # it must be Marshal for now
        Marshal
    end

    def initialize(opts = {})
        options = DEFAULT_OPTS.clone.update(opts)
        @textmode = options[:textmode]
        @color = options[:color]
        @mode = options[:coverage_diff_mode]
        @state_file = options[:coverage_diff_file]
        @diff_cmd = options[:diff_cmd]
        super(options)
    end

    def execute
        case @mode
        when :record
            record_state
        when :compare
            compare_state
        else
            raise "Unknown TextCoverageDiff mode: #{mode.inspect}."
        end
    end

    def record_state
        state = {}
        each_file_pair_sorted do |filename, fileinfo|
            state[filename] = {:lines    => SCRIPT_LINES__[filename],
                               :coverage => fileinfo.coverage.to_a, 
                               :counts   => fileinfo.counts}
        end
        File.open(@state_file, "w") do |f|
            self.SERIALIZER.dump(state, f)
        end
    rescue
        $stderr.puts <<-EOF
Couldn't save coverage data to #{@state_file}.
EOF
    end

    require 'tempfile'
    def compare_state
        return unless verify_diff_available
        begin
            prev_state = File.open(@state_file){|f| self.SERIALIZER.load(f) }
        rescue
            $stderr.puts <<-EOF
Couldn't load coverage data from #{@state_file}.
EOF
            return
        end
        each_file_pair_sorted do |filename, fileinfo|
            old_data = Tempfile.new("#{mangle_filename(filename)}-old")
            new_data = Tempfile.new("#{mangle_filename(filename)}-new")
            if prev_state.has_key? filename
                old_code, old_cov = prev_state[filename].values_at(:lines, :coverage)
                old_code.each_with_index do |line, i|
                    prefix = old_cov[i] ? "   " : "!! "
                    old_data.write "#{prefix}#{line}"
                end
            else
                old_data.write ""
            end
            old_data.close
            SCRIPT_LINES__[filename].each_with_index do |line, i|
                prefix = fileinfo.coverage[i] ? "   " : "!! "
                new_data.write "#{prefix}#{line}"
            end
            new_data.close

            diff = `#{@diff_cmd} -u #{old_data.path} #{new_data.path}`
            new_uncovered_hunks = process_unified_diff(filename, diff)
            old_data.close!
            new_data.close!
            display_hunks(filename, new_uncovered_hunks)
        end
    end

    def display_hunks(filename, hunks)
        return if hunks.empty?
        puts 
        puts "=" * 80
        puts <<EOF
!!!!! Uncovered code introduced in #{filename}

EOF
        hunks.each do |offset, lines|
            puts "### #{filename}:#{offset}"
            if @color
                lines.each do |line| 
                    prefix = (/^!! / !~ line) ? "\e[32;40m" : "\e[31;40m"
                    puts "#{prefix}#{line[3..-1].chomp}\e[37;40m"
                end
            else
                puts lines
            end
        end
    end

    def verify_diff_available
        old_stderr = STDERR.dup
        old_stdout = STDOUT.dup
        # TODO: should use /dev/null or NUL(?), but I don't want to add the
        # win32 check right now
        new_stderr = Tempfile.new("rcov_check_diff")
        STDERR.reopen new_stderr.path
        STDOUT.reopen new_stderr.path

        retval = system "#{@diff_cmd} --version"
        unless retval
            old_stderr.puts <<EOF

The '#{@diff_cmd}' executable seems not to be available.
You can specify which diff executable should be used with --diff-cmd.
If your system doesn't have one, you might want to use Diff::LCS's:
  gem install diff-lcs
and use --diff-cmd=ldiff.
EOF
            return false
        end
        true
    ensure
        STDOUT.reopen old_stdout
        STDERR.reopen old_stderr
        new_stderr.close!
    end

    HUNK_HEADER = /@@ -\d+,\d+ \+(\d+),(\d+) @@/
    def process_unified_diff(filename, diff)
        current_hunk = []
        current_hunk_start = 0
        keep_current_hunk = false
        state = :init
        interesting_hunks = []
        diff.each_with_index do |line, i|
            #puts "#{state} %5d #{line}" % i
            case state
            when :init
                if md = HUNK_HEADER.match(line)
                    current_hunk = []
                    current_hunk_start = md[1].to_i
                    state = :body
                end
            when :body
                case line
                when HUNK_HEADER
                    new_start = $1.to_i
                    if keep_current_hunk
                        interesting_hunks << [current_hunk_start, current_hunk]
                    end
                    current_hunk_start = new_start
                    current_hunk = []
                    keep_current_hunk = false
                when /^-/
                    # ignore
                when /^\+!! /
                    keep_current_hunk = true
                    current_hunk << line[1..-1]
                else
                    current_hunk << line[1..-1]
                end
            end
        end

        interesting_hunks
    end
end


class HTMLCoverage < Formatter
    include XX::XHTML
    include XX::XMLish
    require 'fileutils'
    JAVASCRIPT_PROLOG = <<-EOS

// <![CDATA[
  function toggleCode( id ) {
    if ( document.getElementById )
      elem = document.getElementById( id );
    else if ( document.all )
      elem = eval( "document.all." + id );
    else
      return false;

    elemStyle = elem.style;
    
    if ( elemStyle.display != "block" ) {
      elemStyle.display = "block"
    } else {
      elemStyle.display = "none"
    }

    return true;
  }
  
  // Make cross-references hidden by default
  document.writeln( "<style type=\\"text/css\\">span.cross-ref { display: none }</style>" )
  
  // ]]>
    EOS

    CSS_PROLOG = <<-EOS
span.marked0 {
  background-color: rgb(185, 210, 200);
  display: block;
}
span.marked1 {
  background-color: rgb(190, 215, 205);
  display: block;
}
span.inferred0 {
  background-color: rgb(175, 200, 200);
  display: block;
}
span.inferred1 {
  background-color: rgb(180, 205, 205);
  display: block;
}
span.uncovered0 {
  background-color: rgb(225, 110, 110);
  display: block;
}
span.uncovered1 {
  background-color: rgb(235, 120, 120);
  display: block;
}
span.overview {
  border-bottom: 8px solid black;
}
div.overview {
  border-bottom: 8px solid black;
}
body {
    font-family: verdana, arial, helvetica;
}

div.footer {
    font-size: 68%;
    margin-top: 1.5em;
}

h1, h2, h3, h4, h5, h6 {
    margin-bottom: 0.5em;
}

h5 {
    margin-top: 0.5em;
}

.hidden {
    display: none;
}

div.separator {
    height: 10px;
}
/* Commented out for better readability, esp. on IE */
/*
table tr td, table tr th {
    font-size: 68%;
}

td.value table tr td {
    font-size: 11px;
}
*/

table.percent_graph {
    height: 12px;
    border: #808080 1px solid;
    empty-cells: show;
}

table.percent_graph td.covered {
    height: 10px;
    background: #00f000;
}

table.percent_graph td.uncovered {
    height: 10px;
    background: #e00000;
}

table.percent_graph td.NA {
    height: 10px;
    background: #eaeaea;
}

table.report {
    border-collapse: collapse;
    width: 100%;
}

table.report td.heading {
    background: #dcecff;
    border: #d0d0d0 1px solid;
    font-weight: bold;
    text-align: center;
}

table.report td.heading:hover {
    background: #c0ffc0;
}

table.report td.text {
    border: #d0d0d0 1px solid;
}

table.report td.value {
    text-align: right;
    border: #d0d0d0 1px solid;
}
table.report tr.light {
    background-color: rgb(240, 240, 245);
}
table.report tr.dark {
    background-color: rgb(230, 230, 235);
}
EOS

    DEFAULT_OPTS = {:color => false, :fsr => 30, :destdir => "coverage",
                    :callsites => false, :cross_references => false}
    def initialize(opts = {})
        options = DEFAULT_OPTS.clone.update(opts)
        super(options)
        @dest = options[:destdir]
        @color = options[:color]
        @fsr = options[:fsr]
        @do_callsites = options[:callsites]
        @do_cross_references = options[:cross_references]
        @span_class_index = 0
    end

    def execute
        return if @files.empty?
        FileUtils.mkdir_p @dest
        create_index(File.join(@dest, "index.html"))
        each_file_pair_sorted do |filename, fileinfo|
            create_file(File.join(@dest, mangle_filename(filename)), fileinfo)
        end
    end

    private

    def blurb
        xmlish_ {
                p_ { 
                    t_{ "Generated using the " }
                    a_(:href => "http://eigenclass.org/hiki.rb?rcov") {
                        t_{ "rcov code coverage analysis tool for Ruby" }
                    }
                    t_{ " version #{Rcov::VERSION}." }
                }
        }.pretty
    end

    def output_color_table?
        true
    end

    def default_color
        "rgb(240, 240, 245)"
    end

    def default_title
        "C0 code coverage information"
    end

    def format_overview(*file_infos)
        table_text = xmlish_ {
            table_(:class => "report") {
                thead_ {
                    tr_ { 
                        ["Name", "Total lines", "Lines of code", "Total coverage",
                         "Code coverage"].each do |heading|
                            td_(:class => "heading") { heading }
                         end
                    }
                }
                tbody_ { 
                    color_class_index = 1
                    color_classes = %w[light dark]
                    file_infos.each do |f|
                        color_class_index += 1
                        color_class_index %= color_classes.size
                        tr_(:class => color_classes[color_class_index]) {
                            td_ { 
                                case f.name
                                when "TOTAL": 
                                    t_ { "TOTAL" }
                                else
                                    a_(:href => mangle_filename(f.name)){ t_ { f.name } } 
                                end
                            }
                            [f.num_lines, f.num_code_lines].each do |value| 
                                td_(:class => "value") { tt_{ value } }
                            end
                            [f.total_coverage, f.code_coverage].each do |value|
                                value *= 100
                                td_ { 
                                    table_(:cellpadding => 0, :cellspacing => 0, :align => "right") { 
                                        tr_ { 
                                            td_ {
                                                 tt_ { "%3.1f%%" % value } 
                                                 x_ "&nbsp;"
                                            }
                                            ivalue = value.round
                                            td_ {
                                                table_(:class => "percent_graph", :cellpadding => 0,
                                                   :cellspacing => 0, :width => 100) {
                                                    tr_ {
                                                        td_(:class => "covered", :width => ivalue)
                                                        td_(:class => "uncovered", :width => (100-ivalue))
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            end
                        }
                    end
                }
            }
        }
        table_text.pretty
    end

    class SummaryFileInfo 
        def initialize(obj); @o = obj end
        %w[num_lines num_code_lines code_coverage total_coverage].each do |m|
            define_method(m){ @o.send(m) }
        end
        def name; "TOTAL" end
    end

    def create_index(destname)
        files = [SummaryFileInfo.new(self)] + each_file_pair_sorted.map{|k,v| v}
        title = default_title
        output = xhtml_ { html_ {
            head_ {
                title_{ title }
                style_(:type => "text/css") { t_{ "body { background-color: #{default_color}; }" }  }
                style_(:type => "text/css") { CSS_PROLOG }
                script_(:type => "text/javascript") { h_{ JAVASCRIPT_PROLOG } }
            }
            body_ {
                h3_{
                    t_{ title }
                }
                p_ {
                    t_{ "Generated on #{Time.new.to_s} with " }
                    a_(:href => Rcov::UPSTREAM_URL){ "rcov #{Rcov::VERSION}" }
                }
                p_ { "Threshold: #{@output_threshold}%" } if @output_threshold != 101
                hr_
                x_{ format_overview(*files) }
                hr_
                x_{ blurb }
                p_ {
                    a_(:href => "http://validator.w3.org/check/referer") {
                    img_(:src => "http://www.w3.org/Icons/valid-xhtml11",
                         :alt => "Valid XHTML 1.1!", :height => 31, :width => 88)
                    }
                    a_(:href => "http://jigsaw.w3.org/css-validator/check/referer") {
                        img_(:style => "border:0;width:88px;height:31px",
                             :src => "http://jigsaw.w3.org/css-validator/images/vcss",
                             :alt => "Valid CSS!")
                    }
                }
            }
        } }
        lines = output.pretty.to_a
        lines.unshift lines.pop if /DOCTYPE/ =~ lines[-1]
        File.open(destname, "w") do |f|
            f.puts lines
        end
    end

    def format_lines(file)
        result = ""
        last = nil
        end_of_span = ""
        format_line = "%#{file.num_lines.to_s.size}d"
        file.num_lines.times do |i|
            line = file.lines[i].chomp
            marked = file.coverage[i]
            count = file.counts[i]
            spanclass = span_class(file, marked, count)
            if spanclass != last
                result += end_of_span
                case spanclass
                when nil
                    end_of_span = ""
                else
                    result += %[<span class="#{spanclass}">]
                    end_of_span = "</span>"
                end
            end
            result += %[<a name="line#{i+1}" />] + (format_line % (i+1)) + 
                " " + create_cross_refs(file.name, i+1, CGI.escapeHTML(line)) + "\n"
            last = spanclass
        end
        result += end_of_span
        "<pre>#{result}</pre>"
    end

    class XRefHelper < Struct.new(:file, :line, :klass, :mid, :count) # :nodoc:
    end

    def create_cross_refs(filename, lineno, linetext)
        return linetext unless @callsite_analyzer && @do_callsites
        ret = ""
        if @do_cross_references and 
           (rev_xref = reverse_cross_references_for(filename, lineno))
            refs = rev_xref.map do |classname, methodname, defsite|
                XRefHelper.new(defsite.file, defsite.line, classname, methodname, 0)
            end
            return create_cross_reference_block(linetext, refs, "Calls:") do |ref|
                CGI.escapeHTML("  #{ref.klass}##{ref.mid} at #{normalize_filename(ref.file)}:#{ref.line}")
            end
        end
        refs = cross_references_for(filename, lineno)
        return linetext unless refs
        refs = refs.sort_by{|k,count| count}.map do |ref, count|
            XRefHelper.new(ref.file, ref.line, nil, ref.calling_method, count)
        end
        
        create_cross_reference_block(linetext, refs, 
                                     "Called by:") do |ref|
            r = "%7d   %s" % [ref.count, 
                              "#{normalize_filename(ref.file)}:#{ref.line} in '#{ref.mid}'"]
            CGI.escapeHTML(r)
        end
    end

    def create_cross_reference_block(linetext, refs, toplabel = "", &block)
        ret = ""
        @cross_ref_idx ||= 0
        @known_files ||= sorted_file_pairs.map{|fname, finfo| normalize_filename(fname)}
        ret << %[<a class="crossref-toggle" href="#" onclick="toggleCode('XREF-#{@cross_ref_idx+=1}'); return false;">#{linetext}</a>]
        ret << %[<span class="cross-ref" id="XREF-#{@cross_ref_idx}">]
        ret << %[\n#{toplabel}#{toplabel.empty? ? "" : "\n\n"}]
        refs.each do |dst|
            dstfile = normalize_filename(dst.file)
            dstline = dst.line
            label = yield(dst)
            if @known_files.include? dstfile
                ret << %[<a href="#{mangle_filename(dstfile)}#line#{dstline}">#{label}</a>]
            else
                ret << label
            end
            ret << "\n"
        end
        ret << "</span>"
    end

    def span_class(sourceinfo, marked, count)
        @span_class_index ^= 1
        case marked
        when true
            "marked#{@span_class_index}"
        when :inferred
            "inferred#{@span_class_index}"
        else 
            "uncovered#{@span_class_index}"
        end
    end

    def create_file(destfile, fileinfo)
        #$stderr.puts "Generating #{destfile.inspect}"
        body = format_overview(fileinfo) + format_lines(fileinfo)
        title = fileinfo.name + " - #{default_title}"
        do_ctable = output_color_table?
        output = xhtml_ { html_ {
            head_ { 
                title_{ title } 
                style_(:type => "text/css") { t_{ "body { background-color: #{default_color}; }" }  }
                style_(:type => "text/css") { CSS_PROLOG }
                script_(:type => "text/javascript") { h_ { JAVASCRIPT_PROLOG } }
                style_(:type => "text/css") { h_ { colorscale } }
            }
            body_ {
                h3_{ t_{ default_title } }
                p_ {
                    t_{ "Generated on #{Time.new.to_s} with " }
                    a_(:href => Rcov::UPSTREAM_URL){ "rcov #{Rcov::VERSION}" }
                }
                hr_
                if do_ctable
                    # this kludge needed to ensure .pretty doesn't mangle it
                    x_ { <<EOS
<pre><span class='marked0'>Code reported as executed by Ruby looks like this...
</span><span class='marked1'>and this: this line is also marked as covered.
</span><span class='inferred0'>Lines considered as run by rcov, but not reported by Ruby, look like this,
</span><span class='inferred1'>and this: these lines were inferred by rcov (using simple heuristics).
</span><span class='uncovered0'>Finally, here&apos;s a line marked as not executed.
</span></pre>                       
EOS
                    }
                end
                x_{ body }
                hr_
                x_ { blurb }
                p_ {
                    a_(:href => "http://validator.w3.org/check/referer") {
                    img_(:src => "http://www.w3.org/Icons/valid-xhtml10",
                         :alt => "Valid XHTML 1.0!", :height => 31, :width => 88)
                    }
                    a_(:href => "http://jigsaw.w3.org/css-validator/check/referer") {
                        img_(:style => "border:0;width:88px;height:31px",
                             :src => "http://jigsaw.w3.org/css-validator/images/vcss",
                             :alt => "Valid CSS!")
                    }
                }
            }
        } }
        # .pretty needed to make sure DOCTYPE is in a separate line
        lines = output.pretty.to_a
        lines.unshift lines.pop if /DOCTYPE/ =~ lines[-1]
        File.open(destfile, "w") do |f|
            f.puts lines
        end
    end

    def colorscale
        colorscalebase =<<EOF
span.run%d {
  background-color: rgb(%d, %d, %d);
  display: block;
}
EOF
        cscale = ""
        101.times do |i|
            if @color
                r, g, b = hsv2rgb(220-(2.2*i).to_i, 0.3, 1)
                r = (r * 255).to_i
                g = (g * 255).to_i
                b = (b * 255).to_i
            else
                r = g = b = 255 - i 
            end
            cscale << colorscalebase % [i, r, g, b]
        end
        cscale
    end

    # thanks to kig @ #ruby-lang for this one
    def hsv2rgb(h,s,v)
        return [v,v,v] if s == 0
        h = h/60.0
        i = h.floor
        f = h-i
        p = v * (1-s)
        q = v * (1-s*f)
        t = v * (1-s*(1-f))
        case i
        when 0
            r = v
            g = t
            b = p
        when 1
            r = q
            g = v
            b = p
        when 2
            r = p
            g = v
            b = t
        when 3
            r = p
            g = q
            b = v
        when 4
            r = t
            g = p
            b = v
        when 5
            r = v
            g = p
            b = q
        end
        [r,g,b]
    end
end

class HTMLProfiling < HTMLCoverage

    DEFAULT_OPTS = {:destdir => "profiling"}
    def initialize(opts = {})
        options = DEFAULT_OPTS.clone.update(opts)
        super(options)
        @max_cache = {}
        @median_cache = {}
    end
    
    def default_title
        "Bogo-profile information"
    end
    
    def default_color
        if @color
            "rgb(179,205,255)"
        else
            "rgb(255, 255, 255)"
        end
    end

    def output_color_table?
        false
    end

    def span_class(sourceinfo, marked, count)
        full_scale_range = @fsr # dB
        nz_count = sourceinfo.counts.select{|x| x && x != 0}
        nz_count << 1 # avoid div by 0
        max = @max_cache[sourceinfo] ||= nz_count.max
        #avg = @median_cache[sourceinfo] ||= 1.0 * 
        #    nz_count.inject{|a,b| a+b} / nz_count.size
        median = @median_cache[sourceinfo] ||= 1.0 * nz_count.sort[nz_count.size/2]
        max ||= 2
        max = 2 if max == 1
        if marked == true
            count = 1 if !count || count == 0
            idx = 50 + 1.0 * (500/full_scale_range) * Math.log(count/median) /
                Math.log(10)
            idx = idx.to_i
            idx = 0 if idx < 0
            idx = 100 if idx > 100
            "run#{idx}"
        else 
            nil
        end
    end
end

end # Rcov

# vi: set sw=4:
