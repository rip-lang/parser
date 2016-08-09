require 'parslet'

require_relative './common'
require_relative './expression'
require_relative './reference'

module Rip::Parser::Rules
  module Assignment
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Expression
    include Rip::Parser::Rules::Reference

    rule(:assignment) do
      reference.as(:lhs) >> spaces >>
        equals.as(:location) >> whitespaces >>
        expression.as(:rhs)
    end
  end
end
