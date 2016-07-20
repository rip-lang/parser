require 'parslet'

require_relative './common'
require_relative './number'
require_relative './reference'

module Rip::Parser::Rules
  module Character
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Number
    include Rip::Parser::Rules::Reference

    SPECIAL_ESCAPES = {
      quote_single:    "'",
      quote_double:    '"',
      backslash:       '\\',
      bell:            'a',
      backspace:       'b',
      form_feed:       'f',
      new_line:        'n',
      carriage_return: 'r',
      tab_horizontal:  't',
      tab_vertical:    'v'
    }

    rule(:character) { backtick.as(:location) >> (escape_sequence | character_legal).as(:character) }

    rule(:character_legal) { digit | word_legal }

    rule(:backtick) { str('`') }

    rule(:escape_sequence) { slash_back >> (escape_sequence_unicode | escape_sequence_special | escape_sequence_any) }

    rule(:escape_sequence_unicode) { str('u') >> match['0-9a-f'].repeat(4, 4).as(:escape_unicode) }
    rule(:escape_sequence_special) { SPECIAL_ESCAPES.values.map(&method(:str)).inject(&:|).as(:escape_special) }
    rule(:escape_sequence_any)     { match['\S'].as(:escape_any) }
  end
end
