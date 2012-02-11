$:.push File.expand_path("../lib", __FILE__)
require "rcov/version"

Gem::Specification.new do |s|
  s.name = %q{rcov}
  s.summary = %q{Code coverage analysis tool for Ruby}
  s.description = %q{rcov is a code coverage tool for Ruby.}
  s.version = Rcov::VERSION
  s.date = %q{2012-02-01}
  s.homepage = %q{http://github.com/relevance/rcov}
  s.authors = ["Aaron Bedra (abedra)",
               "Chad Humphries (spicycode)",
               "Jay McGaffigan(hooligan495)",
               "Relevance Inc",
               "Mauricio Fernandez"]
  s.email = %q{aaron@aaronbedra.com}
  s.files = Dir.glob('lib/**/*.rb') + Dir.glob('lib/rcov/templates/*') + Dir.glob('ext/rcovrt/**/*.{c,h,rb}')
  s.extensions = ["ext/rcovrt/extconf.rb"]
  s.executables = ["rcov"]
  s.require_paths = ["lib"]
  s.rdoc_options = ["--title", "rcov code coverage tool"]
  s.add_development_dependency 'rake', '~> 0.9.2'
end
