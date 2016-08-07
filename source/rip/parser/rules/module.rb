require 'parslet'

require_relative './common'
require_relative './assignment'
require_relative './expression'

module Rip::Parser::Rules
  module Module
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Assignment
    include Rip::Parser::Rules::Expression

    rule(:module) { lines.as(:module) }

    rule(:lines) do
      whitespaces? >> (assignment | expression) >> spaces? >> (
        (semicolon | line_break) >> whitespaces? >> lines
      ).repeat >> whitespaces?
    end
  end
end
