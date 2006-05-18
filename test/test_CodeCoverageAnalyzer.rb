
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

  def test_raw_coverage_info
    sample_file = File.join(File.dirname(__FILE__), "sample_01.rb")
    lines = File.readlines(sample_file)
    analyzer = Rcov::CodeCoverageAnalyzer.new
    analyzer.run_hooked{ load sample_file }

    s = lines.size
    
    assert_equal(lines, SCRIPT_LINES__[sample_file][0, s])
    assert(analyzer.analyzed_files.include?(sample_file))
    line_info, cov_info, count_info = analyzer.data(sample_file)
    assert_equal(lines.map{|l| l.chomp}, line_info[0, s])
    assert_equal([true, true, false, false, true, false, true], cov_info[0, s])
    assert_equal([1, 2, 0, 0, 1, 0, 11], count_info[0, s])
    analyzer.reset
    assert_equal(nil, analyzer.data(sample_file))
    assert_equal([], analyzer.analyzed_files)
  end

  def test_differential_coverage_data
    sample_file = File.join(File.dirname(__FILE__), "sample_01.rb")
    lines = File.readlines(sample_file)
    analyzer = Rcov::CodeCoverageAnalyzer.new
    analyzer.run_hooked{ load sample_file }
    line_info, cov_info, count_info = analyzer.data(sample_file)
    assert_equal([1, 2, 0, 0, 1, 0, 11], count_info)
    
    analyzer.reset
    
    sample_file = File.join(File.dirname(__FILE__), "sample_02.rb")
    analyzer.run_hooked{ load sample_file }
    line_info, cov_info, count_info = analyzer.data(sample_file)
    assert_equal([8, 1, 0, 0, 0], count_info)
    
    analyzer.reset
    assert_equal([], analyzer.analyzed_files)
    analyzer.run_hooked{ Rcov::Test::Temporary::Sample02.foo(1, 1) }
    line_info, cov_info, count_info = analyzer.data(sample_file)
    assert_equal([0, 1, 1, 1, 0], count_info)
    analyzer.run_hooked do 
      10.times{ Rcov::Test::Temporary::Sample02.foo(1, 1) }
    end
    line_info, cov_info, count_info = analyzer.data(sample_file)
    assert_equal([0, 11, 11, 11, 0], count_info)
    10.times{ analyzer.run_hooked{ Rcov::Test::Temporary::Sample02.foo(1, 1) } }
    line_info, cov_info, count_info = analyzer.data(sample_file)
    assert_equal([0, 21, 21, 21, 0], count_info)
  end

  def test_compute_raw_difference
    first = {"a" => [1,1,1,1,1]}
    last =  {"a" => [2,1,5,2,1], "b" => [1,2,3,4,5]}
    a = Rcov::CodeCoverageAnalyzer.new
    assert_equal({"a" => [1,0,4,1,0], "b" => [1,2,3,4,5]}, 
                 a.instance_eval{ compute_raw_data_difference(first, last)} )
  end
end
