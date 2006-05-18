
require 'test/unit'
require 'rcov'

class Test_CodeCoverageAnalyzer < Test::Unit::TestCase
    LINES = <<-EOF.to_a
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
  def test_refine_coverage_info
    analyzer = Rcov::CodeCoverageAnalyzer.new
    cover = [1, 1, nil, nil, 0, 5, 5, 5, 0]
    line_info, marked_info, 
      count_info = analyzer.instance_eval{ refine_coverage_info(LINES, cover) }
    assert_equal(LINES.map{|l| l.chomp}, line_info)
    assert_equal([true] * 2 + [false] * 3 + [true] * 3 + [false], marked_info)
    assert_equal([1, 1, 0, 0, 0, 5, 5, 5, 0], count_info)
  end

  def test_analyzed_files_no_analysis
    analyzer = Rcov::CodeCoverageAnalyzer.new
    assert_equal([], analyzer.analyzed_files)
  end

  def xtest_raw_coverage_info
    sample_file = File.join(File.dirname(__FILE__), "sample.rb")
    lines = File.readlines(sample_file)
    analyzer = Rcov::CodeCoverageAnalyzer.new
    analyzer.run_hooked{ load sample_file }
    assert_equal(lines, SCRIPT_LINES__[sample_file])
    assert_equal(Rcov::RCOV__.generate_coverage_info, 
                 analyzer.instance_eval{ raw_coverage_info } )
  end
end
