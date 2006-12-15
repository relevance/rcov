$: << File.dirname(__FILE__)
require 'sample_03'

klass = Rcov::Test::Temporary::Sample03
obj = klass.new
obj.f1                                                                      # >> [[Rcov::Test::Temporary::Sample03#f1 at sample_03_rb.rb:3]], 
obj.f2                                                                      # >> [[Rcov::Test::Temporary::Sample03#f2 at sample_03_rb.rb:7]], 
obj.f3                                                                      # >> [[Rcov::Test::Temporary::Sample03#f3 at sample_03_rb.rb:9]], 
klass.g1                                                                    # >> [[#<Class:Rcov::Test::Temporary::Sample03>#g1 at sample_03_rb.rb:14]], 
klass.g2                                                                    # >> [[#<Class:Rcov::Test::Temporary::Sample03>#g2 at sample_03_rb.rb:18]], 
# Total lines    : 10
# Lines of code  : 9
# Total coverage : 100.0%
# Code coverage  : 100.0%

# Local Variables:
# mode: rcov-xref
# End:
