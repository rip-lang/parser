require 'parslet'

require_relative './common'

module Rip::Parser::Rules
  module Pair
    include ::Parslet

    include Rip::Parser::Rules::Common

    rule(:pair_value) { spaces? >> colon.as(:location) >> spaces? >> expression.as(:value) }
  end
end
