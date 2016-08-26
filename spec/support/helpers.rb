module RSpecHelpers
  def profile_parslet(rip, parslet = :lines)
    binding.pry

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

  def location_for(options = {})
    origin = options[:origin] || Pathname.pwd
    offset = options[:offset] || 0
    line = options[:line] || 1
    column = options[:column] || 1
    Rip::Parser::Location.new(origin, offset, line, column)
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
