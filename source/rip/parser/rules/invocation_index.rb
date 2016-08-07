require 'parslet'

require_relative './common'
require_relative './list'

module Rip::Parser::Rules
  module InvocationIndex
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::List

    rule(:invocation_index) { bracket_open.as(:location) >> csv(expression).as(:index_arguments) >> bracket_close }
  end
end
