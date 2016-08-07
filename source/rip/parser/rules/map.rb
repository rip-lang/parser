require 'parslet'

require_relative './common'
require_relative './list'

module Rip::Parser::Rules
  module Map
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::List

    rule(:map) { brace_open.as(:location) >> whitespaces? >> csv(expression).as(:map) >> whitespaces? >> brace_close }
  end
end
