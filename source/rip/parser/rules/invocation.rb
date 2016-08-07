require 'parslet'

require_relative './common'
require_relative './list'

module Rip::Parser::Rules
  module Invocation
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::List

    rule(:invocation) { parenthesis_open.as(:location) >> csv(expression).as(:arguments) >> parenthesis_close }
  end
end
