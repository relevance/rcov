Gem::Specification.new do |s|
  s.name = %q{rcov}
  s.version = "0.8.1.5.1"

  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.authors = ["Mauricio Fernandez"]
  s.cert_chain = nil
  s.date = %q{2008-08-29}
  s.default_executable = %q{rcov}
  s.description = %q{rcov is a code coverage tool for Ruby. It is commonly used for viewing overall test unit coverage of target code.  It features fast execution (20-300 times faster than previous tools), multiple analysis modes, XHTML and several kinds of text reports, easy automation with Rake via a RcovTask, fairly accurate coverage information through code linkage inference using simple heuristics, colorblind-friendliness...}
  s.email = %q{mfp@acm.org}
  s.executables = ["rcov"]
  s.extensions = ["ext/rcovrt/extconf.rb"]
  s.extra_rdoc_files = ["readme_for_api", "readme_for_rake", "readme_for_rant", "readme_for_vim"]
  s.files = ["bin/rcov", "lib/rcov.rb", "lib/rcov/lowlevel.rb", "lib/rcov/xx.rb", "lib/rcov/version.rb", "lib/rcov/rant.rb", "lib/rcov/report.rb", "lib/rcov/rcovtask.rb", "ext/rcovrt/extconf.rb", "ext/rcovrt/rcovrt.c", "ext/rcovrt/callsite.c", "LEGAL", "LICENSE", "Rakefile", "Rantfile", "readme_for_rake", "readme_for_rant", "readme_for_vim", "readme_for_api", "THANKS", "test/functional_test.rb", "test/file_statistics_test.rb", "test/assets/sample_03.rb", "test/assets/sample_05-new.rb", "test/code_coverage_analyzer_test.rb", "test/assets/sample_04.rb", "test/assets/sample_02.rb", "test/assets/sample_05-old.rb", "test/assets/sample_01.rb", "test/turn_off_rcovrt.rb", "test/call_site_analyzer_test.rb", "test/assets/sample_05.rb", "rcov.vim", "rcov.el", "setup.rb", "BLURB", "CHANGES"]
  s.has_rdoc = true
  s.homepage = %q{http://eigenclass.org/hiki.rb?rcov}
  s.rdoc_options = ["--main", "readme_for_api", "--title", "rcov code coverage tool"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.summary = %q{Code coverage analysis tool for Ruby}
  s.test_files = ["test/functional_test.rb", "test/file_statistics_test.rb", "test/code_coverage_analyzer_test.rb", "test/call_site_analyzer_test.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 1

    if current_version >= 3 then
    else
    end
  else
  end
end

