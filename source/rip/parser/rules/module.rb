require 'parslet'

require_relative './common'
require_relative './expression'

module Rip::Parser::Rules
  module Module
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Expression

    rule(:module) { line.repeat(1).as(:module) }

    rule(:line) { whitespaces? >> expression >> whitespaces? >> expression_terminator? }
  end
end
