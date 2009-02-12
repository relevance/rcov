require File.dirname(__FILE__) + '/test_helper'
require 'rexml/document'
require 'rexml/formatters/pretty'

class TestRexml < Test::Unit::TestCase
  def test_bug_with_long_lines_without_spaces
    pretty_formatter = ::REXML::Formatters::Pretty.new
    long_string = "this-is-a-long-string-without-any-spaces-to-try-to-break-rexml-formatter-and-it-is-over-100-characters-long"
    pretty_formatter.send(:wrap, long_string, 100)

  end
end