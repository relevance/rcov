

require 'test/unit'
require 'rcov'

class Test_CallSiteAnalyzer < Test::Unit::TestCase

  sample_file = File.join(File.dirname(__FILE__), "sample_03.rb")
  load sample_file

  def setup
    @a = Rcov::CallSiteAnalyzer.new
    @o = Rcov::Test::Temporary::Sample03.new
  end

  def test_callsite_compute_raw_difference
    src = [ 
            { ["Foo", "foo"] => {"bar" => 1},
              ["Foo", "bar"] => {"baz" => 10} }, 
            { ["Foo", "foo"] => ["foo.rb", 10] } 
          ]
    dst = [ 
            { ["Foo", "foo"] => {"bar" => 1, "fubar" => 10},
              ["Foo", "baz"] => {"baz" => 10} },
            { ["Foo", "foo"] => ["fooredef.rb", 10],
              ["Foo", "baz"] => ["foo.rb", 20]}
          ]
    expected = [ 
                 { ["Foo", "foo"] => {"fubar" => 10},
                   ["Foo", "baz"] => {"baz"   => 10} },
                 { ["Foo", "foo"] => ["fooredef.rb", 10],
                   ["Foo", "baz"] => ["foo.rb", 20] } 
    ]
               
    assert_equal(expected, 
                 @a.instance_eval{ compute_raw_data_difference(src, dst) } )
  end

  def test_basic_defsite_recording
    @a.run_hooked{ @o.f1 }
    assert_equal(["./test/sample_03.rb", 3], 
                 @a.defsite("Rcov::Test::Temporary::Sample03", "f1"))
    assert_equal(["./test/sample_03.rb", 7], 
                 @a.defsite("Rcov::Test::Temporary::Sample03", "f2"))
  end

  def test_basic_callsite_recording
    @a.run_hooked{ @o.f1 }
    assert(@a.analyzed_classes.include?("Rcov::Test::Temporary::Sample03"))
    assert_equal(%w[f1 f2], @a.analyzed_methods("Rcov::Test::Temporary::Sample03"))
    assert_equal({["./test/sample_03.rb:4:in `f1'"] => 10}, 
                 @a.callsites("Rcov::Test::Temporary::Sample03", "f2"))
  end

  def test_differential_callsite_recording
    @a.run_hooked{ @o.f1 }
    assert(@a.analyzed_classes.include?("Rcov::Test::Temporary::Sample03"))
    assert_equal(%w[f1 f2], @a.analyzed_methods("Rcov::Test::Temporary::Sample03"))
    assert_equal({["./test/sample_03.rb:4:in `f1'"] => 10}, 
                 @a.callsites("Rcov::Test::Temporary::Sample03", "f2"))

    @a.run_hooked{ @o.f1 }
    assert(@a.analyzed_classes.include?("Rcov::Test::Temporary::Sample03"))
    assert_equal(%w[f1 f2], @a.analyzed_methods("Rcov::Test::Temporary::Sample03"))
    assert_equal({["./test/sample_03.rb:4:in `f1'"] => 20}, 
                 @a.callsites("Rcov::Test::Temporary::Sample03", "f2"))
    
    @a.run_hooked{ @o.f3 }
    assert_equal(%w[f1 f2 f3], @a.analyzed_methods("Rcov::Test::Temporary::Sample03"))
    assert_equal({["./test/sample_03.rb:4:in `f1'"] => 120,
                  ["./test/sample_03.rb:11:in `f3'"]=>100 },
                 @a.callsites("Rcov::Test::Temporary::Sample03", "f2"))
  end

  def test_reset
    @a.run_hooked do
      10.times{ @o.f1 }
      @a.reset
      @o.f1
    end
    assert(@a.analyzed_classes.include?("Rcov::Test::Temporary::Sample03"))
    assert_equal(%w[f1 f2], @a.analyzed_methods("Rcov::Test::Temporary::Sample03"))
    assert_equal({["./test/sample_03.rb:4:in `f1'"] => 10}, 
                 @a.callsites("Rcov::Test::Temporary::Sample03", "f2"))

  end

  def test_nested_callsite_recording
    a = Rcov::CallSiteAnalyzer.new
    b = Rcov::CallSiteAnalyzer.new
    a.run_hooked do 
      b.run_hooked { @o.f1 }
      assert(b.analyzed_classes.include?("Rcov::Test::Temporary::Sample03"))
      assert_equal(%w[f1 f2], b.analyzed_methods("Rcov::Test::Temporary::Sample03"))
      assert_equal({["./test/sample_03.rb:4:in `f1'"] => 10}, 
                   b.callsites("Rcov::Test::Temporary::Sample03", "f2"))

      @o.f1
      assert_equal(%w[f1 f2], b.analyzed_methods("Rcov::Test::Temporary::Sample03"))
      assert_equal({["./test/sample_03.rb:4:in `f1'"] => 10}, 
                   b.callsites("Rcov::Test::Temporary::Sample03", "f2"))
      
      assert(a.analyzed_classes.include?("Rcov::Test::Temporary::Sample03"))
      assert_equal(%w[f1 f2], a.analyzed_methods("Rcov::Test::Temporary::Sample03"))
      assert_equal({["./test/sample_03.rb:4:in `f1'"] => 20}, 
                   a.callsites("Rcov::Test::Temporary::Sample03", "f2"))
    end
    b.run_hooked{ @o.f3 }
    assert_equal(%w[f1 f2 f3], b.analyzed_methods("Rcov::Test::Temporary::Sample03"))
    assert_equal({["./test/sample_03.rb:4:in `f1'"] => 110,
                  ["./test/sample_03.rb:11:in `f3'"]=>100 },
                 b.callsites("Rcov::Test::Temporary::Sample03", "f2"))
  end
end
