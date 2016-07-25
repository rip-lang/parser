require 'parslet'

require_relative './common'
require_relative './character'

module Rip::Parser::Rules
  module String
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Character

    rule(:string) { string_symbol | string_double | heredoc }

    rule(:string_symbol) { colon.as(:location) >> character_legal.as(:character).repeat(1).as(:string) }

    rule(:string_double)      { string_parser(quote_double, escape_sequence, :string) }
    rule(:regular_expression) { string_parser(slash_forward, escape_sequence, :regular_expression) }

    rule(:quote_single) { str('\'') }
    rule(:quote_double) { str('"') }

    rule(:heredoc) { heredoc_start.as(:location) >> heredoc_content.as(:string) >> heredoc_end }

    rule(:heredoc_start) { angled_open.repeat(2, 2) >> match['A-Z_'].repeat(1).capture(:heredoc_label) >> line_break }

    rule(:heredoc_content) { (heredoc_end.absent? >> (escape_sequence | any.as(:character))).repeat }

    rule(:heredoc_end) do
      dynamic do |source, context|
        spaces? >> str(context.captures[:heredoc_label]) >> (line_break | eof)
      end
    end

    def string_parser(delimiter, inner_special, label)
      delimiter.as(:location) >> (delimiter.absent? >> (inner_special | any.as(:character))).repeat.as(label) >> delimiter
    end
  end
end
