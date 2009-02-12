require File.dirname(__FILE__) + '/test_helper'
require 'rcov/rexml_extensions'

class TestRexml < Test::Unit::TestCase

  def test_wrap_with_long_lines_without_spaces_should_not_break_wrap
    Rcov::REXMLExtensions.fix_pretty_formatter_wrap
    pretty_formatter = ::REXML::Formatters::Pretty.new
    long_string = "this-is-a-long-string-without-any-spaces-to-try-to-break-rexml-formatter-and-it-is-over-100-characters-long"
    pretty_formatter.instance_eval { wrap(long_string, 100) } # avoid send, it can't bypass private methods in ruby19
  end
  
  def test_wrap_original_behavior_should_be_preserved
    pretty_formatter = REXML::Formatters::Pretty.new
    str = "This string should be wrapped at 40 characters"
    pretty_formatter.instance_eval do
      str = wrap(str, 40)
    end # avoid send, it can't bypass private methods in ruby19
    assert_equal("This string should be wrapped at 40\ncharacters", str)
    
  end
  
end