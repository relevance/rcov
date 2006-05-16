
$rcov_loaded ||= false
$rcov_loaded or load File.join(File.dirname(File.expand_path(__FILE__)), "..", "bin", "rcov")
$rcov_loaded = true

require 'test/unit'

class Test_CodeCoverageAnalyzer < Test::Unit::TestCase
  def test_refine_coverage_info
    analyzer = Rcov::CodeCoverageAnalyzer.new(nil)
    lines = <<-EOF.to_a
puts 1
if foo
  bar
  baz
end
5.times do
  foo
  bar if baz
end
EOF
    cover = [1, 1, nil, nil, 0, 5, 5, 5, 0]
    line_info, marked_info, 
      count_info = analyzer.refine_coverage_info(lines, cover)
    assert_equal(lines.map{|l| l.chomp}, line_info)
    assert_equal([true] * 2 + [false] * 3 + [true] * 3 + [false], marked_info)
    assert_equal([1, 0, 0, 0, 5, 5, 5, 0, 0], count_info)
  end
end
