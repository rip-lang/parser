require 'parslet'

require_relative './common'
require_relative './expression'
require_relative './property'
require_relative './reference'

module Rip::Parser::Rules
  module Assignment
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Expression
    include Rip::Parser::Rules::Property
    include Rip::Parser::Rules::Reference

    rule(:reference_assignment) { reference.as(:lhs) >> assignment_rhs }

    rule(:property_assignment) { (reference.as(:object) >> property).as(:lhs) >> assignment_rhs }

    rule(:assignment_rhs) { spaces >> equals.as(:location) >> whitespaces >> expression.as(:rhs) }
  end
end
