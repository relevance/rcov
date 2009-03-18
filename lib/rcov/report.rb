# rcov Copyright (c) 2004-2006 Mauricio Fernandez <mfp@acm.org>
# See LEGAL and LICENSE for additional licensing information.

require 'pathname'


module Rcov

# Try to fix bugs in the REXML shipped with Ruby 1.8.6
# They affect Mac OSX 10.5.1 users and motivates endless bug reports.
begin
    require 'rexml/formatters/transitive'
    require 'rexml/formatter/pretty'
rescue LoadError
end

require File.expand_path(File.join(File.dirname(__FILE__), 'rexml_extensions' ))

if (RUBY_VERSION == "1.8.6" || RUBY_VERSION == "1.8.7") && defined? REXML::Formatters::Transitive
    class REXML::Document
        remove_method :write rescue nil
        def write( output=$stdout, indent=-1, trans=false, ie_hack=false )
            if xml_decl.encoding != "UTF-8" && !output.kind_of?(Output)
                output = Output.new( output, xml_decl.encoding )
            end
            formatter = if indent > -1
                #if trans
                    REXML::Formatters::Transitive.new( indent )
                #else
                #    REXML::Formatters::Pretty.new( indent, ie_hack )
                #end
            else
                REXML::Formatters::Default.new( ie_hack )
            end
            formatter.write( self, output )
        end
    end

    class REXML::Formatters::Transitive
        remove_method :write_element rescue nil
        def write_element( node, output )
            output << "<#{node.expanded_name}"

            node.attributes.each_attribute do |attr|
                output << " "
                attr.write( output )
            end unless node.attributes.empty?

            if node.children.empty?
                output << "/>"
            else
                output << ">"
                # If compact and all children are text, and if the formatted output
                # is less than the specified width, then try to print everything on
                # one line
                skip = false
                @level += @indentation
                node.children.each { |child|
                    write( child, output )
                }
                @level -= @indentation
                output << "</#{node.expanded_name}>"
            end
            output << "\n"
            output << ' '*@level
        end
    end
    
end
    
end