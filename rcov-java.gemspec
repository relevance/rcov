$:.push File.expand_path("../lib", __FILE__)
require "rcov/version"

Gem::Specification.new do |s|
  s.name = %q{rcov}
  s.version = Rcov::VERSION
  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
    s.authors = ["Relevance",
                 "Chad Humphries (spicycode)",
                 "Aaron Bedra (abedra)",
                 "Jay McGaffigan(hooligan495)",
                 "Mauricio Fernandez"]
  s.date = %q{2012-02-01}
  s.description = %q{rcov is a code coverage tool for Ruby.}
  s.email = %q{aaron@aaronbedra.com}
  s.files = Dir.glob('lib/**/*.rb') + Dir.glob('ext/java/**/*.java')
  s.extensions = ["ext/rcovrt/extconf.rb"]
  s.executables = ["rcov"]
  s.homepage = %q{http://github.com/relevance/rcov}
  s.rdoc_options = ["--title", "rcov code coverage tool"]
  s.require_paths = ["lib"]
  s.required_ruby_version = Gem::Requirement.new("> 0.0.0")
  s.summary = %q{Code coverage analysis tool for Ruby}
  s.test_files = ["test/functional_test.rb",
                  "test/file_statistics_test.rb",
                  "test/code_coverage_analyzer_test.rb",
                  "test/call_site_analyzer_test.rb"]
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 1
    if current_version >= 3 then
    else
    end
  else
  end
end
