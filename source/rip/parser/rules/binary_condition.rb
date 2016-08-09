require 'parslet'

require_relative './common'
require_relative './lambda'
require_relative './keyword'

module Rip::Parser::Rules
  module BinaryCondition
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Lambda
    include Rip::Parser::Rules::Keyword

    rule(:binary_condition) do
      keyword(:if) >> whitespaces? >>
        parenthesis_open >> whitespaces? >>
        expression.as(:condition) >>
        parenthesis_close >> whitespaces? >>
        block_body(:consequence) >> whitespaces? >>
        keyword(:else) >> whitespaces? >> block_body(:alternative)
    end
  end
end
