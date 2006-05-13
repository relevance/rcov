
load File.join(File.dirname(File.expand_path(__FILE__)), "..", "bin", "rcov")
require 'test/unit'

class Test_Sourcefile < Test::Unit::TestCase
  def test_basic_heredocs_are_handled
    lines, coverage, counts = code_info_from_string <<-EOF
    1 puts 1 + 1
    1 puts <<HEREDOC
    0   first line of the heredoc
    0   not marked
    0   but should be
    0 HEREDOC
    1 puts 1
    EOF

    sf = Rcov::SourceFile.new("prev_exp", lines, coverage, counts)
    lines.size.times{|i| assert(sf.coverage[i], 
      "Heredocs should be handled @ #{lines[i].inspect}.") }

  end

  def code_info_from_string(str)
    str = str.gsub(/^\s*/,"")
    [ str.map{|line| line.sub(/^\d+ /, "") },
      str.map{|line| line[/^\d+/].to_i > 0}, 
      str.map{|line| line[/^\d+/].to_i } ]
  end
end
