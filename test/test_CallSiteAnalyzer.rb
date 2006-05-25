

require 'test/unit'
require 'rcov'

class Test_CallSiteAnalyzer < Test::Unit::TestCase
  def f1
    10.times { f2 }
  end

  def f2; 1 end

  def f3
    10.times{ f1 }
    100.times{ f2 }
  end

  def test_basic_callsite_recording
    a = Rcov::CallSiteAnalyzer.new
    a.run_hooked{ f1 }
    assert(a.analyzed_classes.include?("Test_CallSiteAnalyzer"))
    assert_equal(%w[f1 f2], a.analyzed_methods("Test_CallSiteAnalyzer"))
    assert_equal({["./test/test_CallSiteAnalyzer.rb:8:in `f1'"] => 10}, 
                 a.callsites("Test_CallSiteAnalyzer", "f2"))
  end

  def test_differential_callsite_recording
    a = Rcov::CallSiteAnalyzer.new
    a.run_hooked{ f1 }
    assert(a.analyzed_classes.include?("Test_CallSiteAnalyzer"))
    assert_equal(%w[f1 f2], a.analyzed_methods("Test_CallSiteAnalyzer"))
    assert_equal({["./test/test_CallSiteAnalyzer.rb:8:in `f1'"] => 10}, 
                 a.callsites("Test_CallSiteAnalyzer", "f2"))

    a.run_hooked{ f1 }
    assert(a.analyzed_classes.include?("Test_CallSiteAnalyzer"))
    assert_equal(%w[f1 f2], a.analyzed_methods("Test_CallSiteAnalyzer"))
    assert_equal({["./test/test_CallSiteAnalyzer.rb:8:in `f1'"] => 20}, 
                 a.callsites("Test_CallSiteAnalyzer", "f2"))
    
    a.run_hooked{ f3 }
    assert_equal(%w[f1 f2 f3], a.analyzed_methods("Test_CallSiteAnalyzer"))
    assert_equal({["./test/test_CallSiteAnalyzer.rb:8:in `f1'"] => 120,
                  ["./test/test_CallSiteAnalyzer.rb:15:in `f3'"]=>100 },
                 a.callsites("Test_CallSiteAnalyzer", "f2"))
  end

  def test_reset
    a = Rcov::CallSiteAnalyzer.new
    a.run_hooked do
      10.times{ f1 }
      a.reset
      f1
    end
    assert(a.analyzed_classes.include?("Test_CallSiteAnalyzer"))
    assert_equal(%w[f1 f2], a.analyzed_methods("Test_CallSiteAnalyzer"))
    assert_equal({["./test/test_CallSiteAnalyzer.rb:8:in `f1'"] => 10}, 
                 a.callsites("Test_CallSiteAnalyzer", "f2"))

  end

  def test_nested_callsite_recording
    a = Rcov::CallSiteAnalyzer.new
    b = Rcov::CallSiteAnalyzer.new
    a.run_hooked do 
      b.run_hooked { f1 }
      assert(b.analyzed_classes.include?("Test_CallSiteAnalyzer"))
      assert_equal(%w[f1 f2], b.analyzed_methods("Test_CallSiteAnalyzer"))
      assert_equal({["./test/test_CallSiteAnalyzer.rb:8:in `f1'"] => 10}, 
                   b.callsites("Test_CallSiteAnalyzer", "f2"))

      f1
      assert_equal(%w[f1 f2], b.analyzed_methods("Test_CallSiteAnalyzer"))
      assert_equal({["./test/test_CallSiteAnalyzer.rb:8:in `f1'"] => 10}, 
                   b.callsites("Test_CallSiteAnalyzer", "f2"))
      
      assert(a.analyzed_classes.include?("Test_CallSiteAnalyzer"))
      assert_equal(%w[f1 f2], a.analyzed_methods("Test_CallSiteAnalyzer"))
      assert_equal({["./test/test_CallSiteAnalyzer.rb:8:in `f1'"] => 20}, 
                   a.callsites("Test_CallSiteAnalyzer", "f2"))
    end
    b.run_hooked{ f3 }
    assert_equal(%w[f1 f2 f3], b.analyzed_methods("Test_CallSiteAnalyzer"))
    assert_equal({["./test/test_CallSiteAnalyzer.rb:8:in `f1'"] => 110,
                  ["./test/test_CallSiteAnalyzer.rb:15:in `f3'"]=>100 },
                 b.callsites("Test_CallSiteAnalyzer", "f2"))
  end
end
