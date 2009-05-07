# xx can be redistributed and used under the following conditions
# (just keep the following copyright notice, list of conditions and disclaimer
# in order to satisfy rcov's "Ruby license" and xx's license simultaneously).
# 
#ePark Labs Public License version 1
#Copyright (c) 2005, ePark Labs, Inc. and contributors
#All rights reserved.
#
#Redistribution and use in source and binary forms, with or without modification,
#are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#  3. Neither the name of ePark Labs nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
#THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
#ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
#ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
#LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
#ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
#(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
#SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

unless defined? $__xx_rb__

require "rexml/document"


module XX

  VERSION = "0.1.0"

  %w(
    CRAZY_LIKE_A_HELL
    PERMISSIVE
    STRICT
    ANY
  ).each{|c| const_set c, c}

  class Document

    attr "doc"
    attr "stack"
    attr "size"

    def initialize(*a, &b)
      @doc = ::REXML::Document::new(*a, &b)
      @stack = [@doc]
      @size = 0
    end
    
    def top
      @stack.last
    end
    
    def push(element)
      @stack.push element
    end

    def pop
      @stack.pop unless @stack.size == 1
    end

    def tracking_additions
      n = @size
      yield
      return @size - n
    end

    def to_str(port = "")
      @doc.write port, indent=-1, transitive=false, ie_hack=true
      port
    end
    
    alias_method "to_s", "to_str"

    def pretty(port = '') 
      @doc.write port, indent=2, transitive=false, ie_hack=true
      port
    end

    def create(element)
      push element
      begin
        object = nil
        additions =
          tracking_additions do
            object = yield element if block_given?
          end
        if object and additions.zero?
          self << object
        end
      ensure
        pop
      end
      self << element
      element

    end
    def << object

      t, x = top, object

      if x
        case t
          when ::REXML::Document

            begin
              t <<
                case x
                  when ::REXML::Document
                    x.root || ::REXML::Text::new(x.to_s)
                  when ::REXML::Element
                    x
                  when ::REXML::CData
                    x
                  when ::REXML::Text
                    x
                  else # string
                    ::REXML::Text::new(x.to_s)
                end
            rescue
              if t.respond_to? "root"
                t = t.root
                retry
              else
                raise
              end
            end

          when ::REXML::Element
            t <<
              case x
                when ::REXML::Document
                  x.root || ::REXML::Text::new(x.to_s)
                when ::REXML::Element
                  x
                when ::REXML::CData
                  #::REXML::Text::new(x.write(""))
                  x
                when ::REXML::Text
                  x
                else # string
                  ::REXML::Text::new(x.to_s)
              end

          when ::REXML::Text
            t <<
              case x
                when ::REXML::Document
                  x.write ""
                when ::REXML::Element
                  x.write ""
                when ::REXML::CData
                  x.write ""
                when ::REXML::Text
                  x.write ""
                else # string
                  x.to_s
              end

          else # other - try anyhow 
            t <<
              case x
                when ::REXML::Document
                  x.write ""
                when ::REXML::Element
                  x.write ""
                when ::REXML::CData
                  x.write ""
                when ::REXML::Text
                  x.write ""
                else # string
                  x.to_s
              end
        end
      end

      @size += 1
      self

    end

  end

  module Markup

    class Error < ::StandardError; end

    module InstanceMethods

      def method_missing m, *a, &b

        m = m.to_s

        tag_method, tag_name = xx_class::xx_tag_method_name m

        c_method_missing = xx_class::xx_config_for "method_missing", xx_which
        c_tags = xx_class::xx_config_for "tags", xx_which

        pat =
          case c_method_missing
            when ::XX::CRAZY_LIKE_A_HELL
              %r/.*/
            when ::XX::PERMISSIVE
              %r/_$/o
            when ::XX::STRICT
              %r/_$/o
            else
              super(m.to_sym, *a, &b)
          end

        super(m.to_sym, *a, &b) unless m =~ pat

        if c_method_missing == ::XX::STRICT
          super(m.to_sym, *a, &b) unless c_tags.include? tag_name
        end

        ret, defined = nil

        begin
          xx_class::xx_define_tmp_method tag_method
          xx_class::xx_define_tag_method tag_method, tag_name
          ret = send tag_method, *a, &b
          defined = true
        ensure
          xx_class::xx_remove_tag_method tag_method unless defined
        end

        ret

      end
      def xx_tag_ tag_name, *a, &b

        tag_method, tag_name = xx_class::xx_tag_method_name tag_name 

        ret, defined = nil

        begin
          xx_class::xx_define_tmp_method tag_method
          xx_class::xx_define_tag_method tag_method, tag_name
          ret = send tag_method, *a, &b
          defined = true
        ensure
          xx_class::xx_remove_tag_method tag_method unless defined
        end

        ret

      end
      alias_method "g_", "xx_tag_"
      def xx_which *argv 

        @xx_which = nil unless defined? @xx_which
        if argv.empty?
          @xx_which
        else
          xx_which = @xx_which
          begin
            @xx_which = argv.shift 
            return yield
          ensure
            @xx_which = xx_which
          end
        end

      end
      def xx_with_doc_in_effect *a, &b

        @xx_docs ||= []
        doc = ::XX::Document::new(*a)
        ddoc = doc.doc
        begin
          @xx_docs.push doc
          b.call doc if b

          doctype = xx_config_for "doctype", xx_which
          if doctype
            unless ddoc.doctype
              doctype = ::REXML::DocType::new doctype unless 
                ::REXML::DocType === doctype
              ddoc << doctype
            end
          end

          xmldecl = xx_config_for "xmldecl", xx_which
          if xmldecl
            if ddoc.xml_decl == ::REXML::XMLDecl::default
              xmldecl = ::REXML::XMLDecl::new xmldecl unless
                ::REXML::XMLDecl === xmldecl
              ddoc << xmldecl
            end
          end

          return doc
        ensure
          @xx_docs.pop
        end

      end
      def xx_doc

        @xx_docs.last rescue raise "no xx_doc in effect!"

      end
      def xx_text_ *objects, &b

        doc = xx_doc

        text =
          ::REXML::Text::new("", 
            respect_whitespace=true, parent=nil
          )

        objects.each do |object| 
          text << object.to_s if object
        end

        doc.create text, &b

      end
      alias_method "text_", "xx_text_"
      alias_method "t_", "xx_text_"
      def xx_markup_ *objects, &b

        doc = xx_doc

        doc2 = ::REXML::Document::new ""

        objects.each do |object| 
          (doc2.root ? doc2.root : doc2) << ::REXML::Document::new(object.to_s)
        end


        ret = doc.create doc2, &b
        puts doc2.to_s
        STDIN.gets
        ret

      end
      alias_method "x_", "xx_markup_"
      def xx_any_ *objects, &b

        doc = xx_doc
        nothing = %r/.^/m

        text =
          ::REXML::Text::new("", 
            respect_whitespace=true, parent=nil, raw=true, entity_filter=nil, illegal=nothing
          )

        objects.each do |object| 
          text << object.to_s if object
        end

        doc.create text, &b

      end
      alias_method "h_", "xx_any_"
      remove_method "x_" if instance_methods.include? "x_"
      alias_method "x_", "xx_any_" # supplant for now
      def xx_cdata_ *objects, &b

        doc = xx_doc

        cdata = ::REXML::CData::new ""

        objects.each do |object| 
          cdata << object.to_s if object
        end

        doc.create cdata, &b

      end
      alias_method "c_", "xx_cdata_"
      def xx_parse_attributes string

        string = string.to_s
        tokens = string.split %r/,/o
        tokens.map{|t| t.sub!(%r/[^=]+=/){|key_eq| key_eq.chop << " : "}}
        xx_parse_yaml_attributes(tokens.join(','))

      end
      alias_method "att_", "xx_parse_attributes"
      def xx_parse_yaml_attributes string

        require "yaml"
        string = string.to_s
        string = "{" << string unless string =~ %r/^\s*[{]/o
        string = string << "}" unless string =~ %r/[}]\s*$/o
        obj = ::YAML::load string
        raise ArgumentError, "<#{ obj.class }> not Hash!" unless Hash === obj
        obj

      end
      alias_method "at_", "xx_parse_yaml_attributes"
      alias_method "yat_", "xx_parse_yaml_attributes"
      def xx_class

        @xx_class ||= self.class

      end
      def xx_tag_method_name *a, &b 

        xx_class.xx_tag_method_name(*a, &b)

      end
      def xx_define_tmp_method *a, &b 

        xx_class.xx_define_tmp_methodr(*a, &b)

      end
      def xx_define_tag_method *a, &b 

        xx_class.xx_define_tag_method(*a, &b)

      end
      def xx_remove_tag_method *a, &b 

        xx_class.xx_tag_remove_method(*a, &b)

      end
      def xx_ancestors

        raise Error, "no xx_which in effect" unless xx_which
        xx_class.xx_ancestors xx_which

      end
      def xx_config

        xx_class.xx_config

      end
      def xx_config_for *a, &b

        xx_class.xx_config_for(*a, &b)

      end
      def xx_configure *a, &b

        xx_class.xx_configure(*a, &b)

      end

    end

    module ClassMethods

      def xx_tag_method_name m

        m = m.to_s
        tag_method, tag_name = m, m.gsub(%r/_+$/, "")
        [ tag_method, tag_name ]

      end
      def xx_define_tmp_method m 

        define_method(m){ raise NotImplementedError, m.to_s }

      end
      def xx_define_tag_method tag_method, tag_name = nil

        tag_method = tag_method.to_s
        tag_name ||= tag_method.gsub %r/_+$/, ""

        remove_method tag_method if instance_methods.include? tag_method
        module_eval <<-code, __FILE__, __LINE__+1
          def #{ tag_method } *a, &b
            hashes, nothashes = a.partition{|x| Hash === x}

            doc = xx_doc
            element = ::REXML::Element::new '#{ tag_name }'

            hashes.each{|h| h.each{|k,v| element.add_attribute k.to_s, v}}
            nothashes.each{|nh| element << ::REXML::Text::new(nh.to_s)}

            doc.create element, &b
          end
        code
        tag_method

      end
      def xx_remove_tag_method tag_method

        remove_method tag_method rescue nil

      end
      def xx_ancestors xx_which = self

        list = []
        ancestors.each do |a|
          list << a if a < xx_which
        end
        xx_which.ancestors.each do |a|
          list << a if a <= Markup
        end
        list

      end
      def xx_config

        @@xx_config ||= Hash::new{|h,k| h[k] = {}}

      end
      def xx_config_for key, xx_which = nil 

        key = key.to_s 
        xx_which ||= self
        xx_ancestors(xx_which).each do |a|
          if xx_config[a].has_key? key
            return xx_config[a][key]
          end
        end
        nil

      end
      def xx_configure key, value, xx_which = nil 

        key = key.to_s
        xx_which ||= self
        xx_config[xx_which][key] = value

      end

    end

    extend ClassMethods
    include InstanceMethods

    def self::included other, *a, &b

      ret = super
      other.module_eval do
        include Markup::InstanceMethods
        extend Markup::ClassMethods
        class << self
          define_method("included", Markup::XX_MARKUP_RECURSIVE_INCLUSION_PROC)
        end
      end
      ret

    end
    XX_MARKUP_RECURSIVE_INCLUSION_PROC = method("included").to_proc

    xx_configure "method_missing", XX::PERMISSIVE
    xx_configure "tags", []
    xx_configure "doctype", nil
    xx_configure "xmldecl", nil

  end

  module XHTML

    include Markup
    xx_configure "doctype", %(html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")

    def xhtml_ which = XHTML, *a, &b

      xx_which(which) do
        doc = xx_with_doc_in_effect(*a, &b)
        ddoc = doc.doc
        root = ddoc.root
        if root and root.name and root.name =~ %r/^html$/i 
          if root.attribute("lang",nil).nil? or root.attribute("lang",nil).to_s.empty?
            root.add_attribute "lang", "en"
          end
          if root.attribute("xml:lang").nil? or root.attribute("xml:lang").to_s.empty?
            root.add_attribute "xml:lang", "en"
          end
          if root.namespace.nil? or root.namespace.to_s.empty?
            root.add_namespace "http://www.w3.org/1999/xhtml"
          end
        end
        doc
      end

    end

    module Strict

      include XHTML
      xx_configure "doctype", %(html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd")
      xx_configure "tags", %w(
        html head body div span DOCTYPE title link meta style p
        h1 h2 h3 h4 h5 h6 strong em abbr acronym address bdo blockquote cite q code
        ins del dfn kbd pre samp var br a base img
        area map object param ul ol li dl dt dd table
        tr td th tbody thead tfoot col colgroup caption form input
        textarea select option optgroup button label fieldset legend script noscript b
        i tt sub sup big small hr
      )
      xx_configure "method_missing", ::XX::STRICT

      def xhtml_ which = XHTML::Strict, *a, &b

        super(which, *a, &b)

      end

    end

    module Transitional

      include XHTML
      xx_configure "doctype", %(html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd")
      def xhtml_ which = XHTML::Transitional, *a, &b

        super(which, *a, &b)

      end

    end

  end

  module HTML4

    include Markup
    xx_configure "doctype", %(html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN")
 
    def html4_ which = HTML4, *a, &b

      xx_which(which){ xx_with_doc_in_effect(*a, &b) }

    end

    module Strict

      include HTML4
      xx_configure "doctype", %(html PUBLIC "-//W3C//DTD HTML 4.01 Strict//EN")
      xx_configure "tags", %w(
        html head body div span DOCTYPE title link meta style p
        h1 h2 h3 h4 h5 h6 strong em abbr acronym address bdo blockquote cite q code
        ins del dfn kbd pre samp var br a base img
        area map object param ul ol li dl dt dd table
        tr td th tbody thead tfoot col colgroup caption form input
        textarea select option optgroup button label fieldset legend script noscript b
        i tt sub sup big small hr
      )
      xx_configure "method_missing", ::XX::STRICT
      def html4_ which = HTML4::Strict, *a, &b

        super(which, *a, &b)

      end

    end

    module Transitional

      include HTML4
      xx_configure "doctype", %(html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN")
      def html4_ which = HTML4::Transitional, *a, &b

        super(which, *a, &b)

      end

    end

  end
  HTML = HTML4

  module XML

    include Markup
    xx_configure "xmldecl", ::REXML::XMLDecl::new

    def xml_ *a, &b

      xx_which(XML){ xx_with_doc_in_effect(*a, &b)}

    end

  end

end

$__xx_rb__ = __FILE__
end










#
# simple examples - see samples/ dir for more complete examples
#

if __FILE__ == $0

  class Table < ::Array
    include XX::XHTML::Strict
    include XX::HTML4::Strict
    include XX::XML

    def doc 
      html_{
        head_{ title_{ "xhtml/html4/xml demo" } }

        div_{
          h_{ "< malformed html & un-escaped symbols" }
        }

        t_{ "escaped & text > <" }

        x_{ "<any_valid> xml </any_valid>" }

        div_(:style => :sweet){ 
          em_ "this is a table"

          table_(:width => 42, :height => 42){
            each{|row| tr_{ row.each{|cell| td_ cell } } }
          }
        }

        script_(:type => :dangerous){ cdata_{ "javascript" } }
      }
    end
    def to_xhtml
      xhtml_{ doc }
    end
    def to_html4
      html4_{ doc }
    end
    def to_xml
      xml_{ doc }
    end
  end

  table = Table[ %w( 0 1 2 ), %w( a b c ) ]
  
  methods = %w( to_xhtml to_html4 to_xml )

  methods.each do |method|
    2.times{ puts "-" * 42 }
    puts(table.send(method).pretty)
    puts
  end

end
