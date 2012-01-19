if RUBY_VERSION =~ /1.9/
  puts "**** Ruby 1.9 is not supported. Please switch to simplecov ****"
  Kernel.exit 1
end

require 'mkmf'

dir_config("gcov")
if ENV["USE_GCOV"] and Config::CONFIG['CC'] =~ /gcc/ and 
  have_library("gcov", "__gcov_open")

  $CFLAGS << " -fprofile-arcs -ftest-coverage"
  create_makefile("rcovrt", "1.8/")
else
  create_makefile("rcovrt", "1.8/")
end
