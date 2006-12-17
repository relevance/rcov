$: << File.dirname(__FILE__)                                                #o
require 'sample_03'                                                         #o
                                                                            #o
klass = Rcov::Test::Temporary::Sample03                                     #o
obj = klass.new                                                             #o
obj.f1                                                                      # >> [[Rcov::Test::Temporary::Sample03#f1 at sample_03_rb.rb:3]], 
obj.f2                                                                      # >> [[Rcov::Test::Temporary::Sample03#f2 at sample_03_rb.rb:7]], 
obj.f3                                                                      # >> [[Rcov::Test::Temporary::Sample03#f3 at sample_03_rb.rb:9]], 
#klass.g1 uncovered                                                         #o
klass.g2                                                                    # >> [[#<Class:Rcov::Test::Temporary::Sample03>#g2 at sample_03_rb.rb:18]], 
# Total lines    : 10
# Lines of code  : 8
# Total coverage : 100.0%
# Code coverage  : 100.0%

# Local Variables:
# mode: rcov-xref
# End:
