require 'parslet'

require_relative './common'
require_relative './reference'

module Rip::Parser::Rules
  module Property
    SPECIAL_NAMES = [
      '/',
      '/%',
      '<',
      '<<',
      '<=',
      '<=>',
      '>',
      '>>',
      '>=',
      '[]',
      '|>'
    ]

    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Reference

    rule(:property) { whitespaces? >> dot.as(:location) >> whitespaces? >> property_name.as(:property_name) }

    rule(:property_name) { property_name_special | word }

    rule(:property_name_special) { SPECIAL_NAMES.map(&method(:str)).inject(&:|) }
  end
end
