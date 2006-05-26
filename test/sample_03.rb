
module Rcov; module Test; module Temporary; class Sample03
  def f1                # MUST NO CHANGE the position or the tests will break
    10.times { f2 }
  end

  def f2; 1 end

  def f3
    10.times{ f1 }
    100.times{ f2 }
  end                   # MUST NO CHANGE up to this line
end end end end
