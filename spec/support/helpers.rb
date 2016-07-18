require 'hashie'

module RSpecHelpers
  def recognizes_as_expected(description, *flags, &block)
    context description, *flags do
      instance_exec &block
      specify do
        if defined? expected_raw
          expect(rip).to parse_raw_as(expected_raw)
        end

        if defined? expected
          expect(rip).to parse_as(Hashie::Mash.new(expected))
        end
      end
    end
  end

  def profile_parslet(rip, parslet = :lines)
    result = RubyProf.profile do
      parser(rip).send(parslet).parse_tree
    end

    result.eliminate_methods!([
      /Array/,
      /Class/,
      /Enumerable/,
      /Fixnum/,
      /Hash/,
      /Kernel/,
      /Module/,
      /Object/,
      /Proc/,
      /Regexp/,
      /String/,
      /Symbol/
    ])

    tree = RubyProf::CallInfoPrinter.new(result)
    tree.print(STDOUT)
  end

  def new_location(origin, offset, line, column)
    Rip::Parser::Location.new(origin, offset, line, column)
  end

  def location_for(options = {})
    origin = options[:origin] || Pathname.pwd
    offset = options[:offset] || 0
    line = options[:line] || 1
    column = options[:column] || 1
    new_location(origin, offset, line, column)
  end

  def raw_parse_tree(source_code)
    Rip::Parser.raw_tree(Pathname.pwd, source_code)
  end

  def parse_tree(source_code)
    Rip::Parser.tree(Pathname.pwd, source_code)
  end

  def rip_string_raw(string)
    string.split('').map do |s|
      { :character => s }
    end
  end

  def rip_string(string)
    rip_string_raw(string).map do |s|
      s.merge(:location => s[:character])
    end
  end

  # http://apidock.com/rails/String/strip_heredoc
  def strip_heredoc(string)
    indent = string.scan(/^[ \t]*(?=\S)/).min.size
    string.gsub(/^[ \t]{#{indent}}/, '')
  end

  def clean_inspect(ast)
    ast.inspect
      .gsub(/@\d+/, '')
      .gsub('\\"', '\'')
      .gsub(/:0x[0-9a-f]+/, '')
      .gsub('Rip::Nodes::', '')
      .gsub('Rip::Utilities::Location ', '')
      .gsub(/ @location=\#\<([^>]+)>/, '@\1')
  end
end

RSpec.configure do |config|
  config.include RSpecHelpers

  config.extend RSpecHelpers
end
