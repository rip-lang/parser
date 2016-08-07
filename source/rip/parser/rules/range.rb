require 'parslet'

require_relative './common'
require_relative './character'

module Rip::Parser::Rules
  module Range
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Reference

    rule(:range_end) { spaces? >> (dot >> dot).as(:location) >> spaces? >> expression.as(:end) }
  end
end
