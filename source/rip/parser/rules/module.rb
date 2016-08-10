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

    rule(:module) { root_lines.as(:module) }

    rule(:root_lines) do
      whitespaces? >> (reference_assignment | expression) >> spaces? >> (
        (semicolon | line_break) >> whitespaces? >> root_lines
      ).repeat >> whitespaces?
    end

    rule(:nested_lines) do
      whitespaces? >> (property_assignment | reference_assignment | expression) >> spaces? >> (
        (semicolon | line_break) >> whitespaces? >> nested_lines
      ).repeat >> whitespaces?
    end
  end
end
