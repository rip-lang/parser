require 'parslet'

require_relative './common'
require_relative './number'

module Rip::Parser::Rules
  module DateTime
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Number

    rule(:date_time) { date.as(:date) >> str('T') >> time.as(:time) }

    rule(:date) do
      digit.repeat(4, 4).as(:year) >> dash >>
        digit.repeat(2, 2).as(:month) >> dash >>
        digit.repeat(2, 2).as(:day)
    end

    rule(:time) do
      digit.repeat(2, 2).as(:hour) >> colon >>
        digit.repeat(2, 2).as(:minute) >> colon >>
        digit.repeat(2, 2).as(:second) >>
        (dot >> digits.as(:sub_second)).maybe >>
        (
          sign >> digit.repeat(2, 2).as(:hour) >> digit.repeat(2, 2).as(:minute)
        ).as(:offset).maybe
    end
  end
end
