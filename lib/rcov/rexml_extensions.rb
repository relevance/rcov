require 'rexml/document'
require 'rexml/formatters/pretty'

module Rcov
  module REXMLExtensions
  
    def self.fix_pretty_formatter_wrap
      REXML::Formatters::Pretty.class_eval do
        include PrettyFormatterWrapFix
      end
    end

    # Fix for this bug: http://clint-hill.com/2008/10/02/a-bug-in-ruby-did-i-just-find-that/
    # Also known from this fun exception:
    #
    #    /usr/local/ruby/lib/ruby/1.8/rexml/formatters/pretty.rb:131:in
    #    `[]': no implicit conversion from nil to integer (TypeError)
    #
    # This bug was fixed in Ruby with this changeset http://svn.ruby-lang.org/cgi-bin/viewvc.cgi?view=rev&revision=19487
    # ...which should mean that this bug only affects Ruby 1.8.6.  The latest stable version of 1.8.7 (and up) should be fine.
    module PrettyFormatterWrapFix

      def self.included(base)
        base.class_eval do
          def wrap(string, width)
            # Recursively wrap string at width.
            return string if string.length <= width
            place = string.rindex(' ', width) # Position in string with last ' ' before cutoff
            return string if place.nil?
            return string[0,place] + "\n" + wrap(string[place+1..-1], width)
          end
        end
      end
    
    end
  
    def self.init!
      if RUBY_VERSION == "1.8.6"
        fix_pretty_formatter_wrap
      end
    end
  end
  
end