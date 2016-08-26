require 'parslet'

require_relative './common'
require_relative './number'
require_relative './reference'

module Rip::Parser::Rules
  module Unit
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Number
    include Rip::Parser::Rules::Reference

    rule(:unit) { number.as(:magnitude) >> word.as(:label) }
  end
end
