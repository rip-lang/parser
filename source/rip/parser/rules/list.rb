require 'parslet'

require_relative './common'

module Rip::Parser::Rules
  module List
    include ::Parslet

    include Rip::Parser::Rules::Common

    rule(:list) { bracket_open.as(:location) >> whitespaces? >> csv(expression).as(:list) >> whitespaces? >> bracket_close }

    def csv(value)
      _value = whitespaces? >> value >> whitespaces?
      (_value >> (comma >> _value).repeat).repeat(0, 1)
    end
  end
end
