
load File.join(File.dirname(File.expand_path(__FILE__)), "..", "bin", "rcov")
require 'test/unit'

class Test_Sourcefile < Test::Unit::TestCase
  def test_heredocs_basic
    verify_everything_marked "heredocs-basic.rb", <<-EOF
      1 puts 1 + 1
      1 puts <<HEREDOC
      0   first line of the heredoc
      0   not marked
      0   but should be
      0 HEREDOC
      1 puts 1
    EOF
    verify_everything_marked "squote", <<-EOF
      1 puts <<'HEREDOC'
      0   first line of the heredoc
      0 HEREDOC
    EOF
    verify_everything_marked "dquote", <<-EOF
      1 puts <<"HEREDOC"
      0   first line of the heredoc
      0 HEREDOC
    EOF
    verify_everything_marked "xquote", <<-EOF
      1 puts <<`HEREDOC`
      0   first line of the heredoc
      0 HEREDOC
    EOF
  end
  def test_heredocs_multiple
    verify_everything_marked "multiple-unquoted", <<-EOF
      1 puts <<HEREDOC, <<HERE2
      0   first line of the heredoc
      0 HEREDOC
      0   second heredoc
      0 HERE2
    EOF
    verify_everything_marked "multiple-quoted", <<-EOF
      1 puts <<'HEREDOC', <<`HERE2`, <<"HERE3"
      0   first line of the heredoc
      0 HEREDOC
      0   second heredoc
      0 HERE2
      0 dsfdsfffd
      0 HERE3
    EOF
    verify_everything_marked "same-identifier", <<-EOF
      1 puts <<H, <<H
      0 foo
      0 H
      0 bar
      0 H
    EOF
  end
  def test_ignore_non_heredocs
    verify_marked_exactly "bitshift-numeric", [0], <<-EOF
    1 puts 1<<2
    0 return if foo
    0 do_stuff()
    0 2
    EOF
    verify_marked_exactly "bitshift-symbolic", [0], <<-EOF
    1 puts 1<<LSHIFT
    0 return if bar
    0 do_stuff()
    0 LSHIFT
    EOF
    verify_marked_exactly "bitshift-symbolic-multi", 0..3, <<-EOF
    1 puts <<EOF, 1<<LSHIFT
    0 random text
    0 EOF
    1 return if bar
    0 puts "foo"
    0 LSHIFT
    EOF
  end

  def verify_marked_exactly(testname, marked_indices, str)
    lines, coverage, counts = code_info_from_string(str)

    sf = Rcov::SourceFile.new(testname, lines, coverage, counts)
    lines.size.times do |i|
      if marked_indices.include? i
        assert(sf.coverage[i], "Test #{testname}; " + 
               "line should have been marked: #{lines[i].inspect}.")
      else
        assert(!sf.coverage[i], "Test #{testname}; " + 
               "line should not have been marked: #{lines[i].inspect}.")
      end
    end
  end
  
  def verify_everything_marked(testname, str)
    verify_marked_exactly(testname, (0...str.size).to_a, str)
  end


  def code_info_from_string(str)
    str = str.gsub(/^\s*/,"")
    [ str.map{|line| line.sub(/^\d+ /, "") },
      str.map{|line| line[/^\d+/].to_i > 0}, 
      str.map{|line| line[/^\d+/].to_i } ]
  end
end
