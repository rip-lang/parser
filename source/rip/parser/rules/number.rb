require 'parslet'

require_relative './common'

module Rip::Parser::Rules
  module Number
    include ::Parslet

    include Rip::Parser::Rules::Common

    rule(:number) { sign.maybe >> (decimal | integer) }

    rule(:sign) { match['+-'].as(:sign) }

    rule(:decimal) { integer >> dot >> digits.as(:decimal) }
    rule(:integer) { digits.as(:integer) }

    rule(:digit) { match['0-9'] }
    rule(:digits) { digit.repeat(1) >> (underscore.maybe >> digit.repeat(1)).repeat }
  end
end
