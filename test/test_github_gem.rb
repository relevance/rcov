require File.dirname(__FILE__) + '/test_helper'
require 'yaml'
require 'rubygems/specification'
 
class TestGithubGem < Test::Unit::TestCase

  def test_spec_should_validate
    Dir.chdir(File.join(File.dirname(__FILE__), *%w[..])) do
      data = File.read("rcov.gemspec")
      spec = nil

      if data !~ %r{!ruby/object:Gem::Specification}
       Thread.new { spec = eval("$SAFE = 3\n#{data}") }.join
      else
       spec = YAML.load(data)
      end

      assert spec.validate
    end
  end
end
