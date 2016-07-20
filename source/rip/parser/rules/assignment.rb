require 'parslet'

require_relative './common'
require_relative './expression'

module Rip::Parser::Rules
  module Assignment
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Expression

    rule(:assignment) { equals >> whitespaces >> expression }
  end
end
