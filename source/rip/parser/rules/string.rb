require 'parslet'

require_relative './common'
require_relative './character'

module Rip::Parser::Rules
  module String
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Character

    rule(:string) { string_symbol | string_double }

    rule(:string_symbol) { colon.as(:location) >> character_legal.as(:character).repeat(1).as(:string) }

    rule(:string_double)      { string_parser(quote_double, escape_sequence.as(:character), :string) }
    rule(:regular_expression) { string_parser(slash_forward, escape_sequence.as(:character), :regular_expression) }

    rule(:quote_single) { str('\'') }
    rule(:quote_double) { str('"') }

    rule(:heredoc) do
      scope do
        heredoc_start >> heredoc_content.as(:string) >> heredoc_end
      end
    end

    rule(:heredoc_start) { angled_open.repeat(2, 2).as(:location) >> heredoc_label >> line_break }
    rule(:heredoc_label) { match['A-Z_'].repeat(1).capture(:heredoc_label) }

    rule(:heredoc_content) { (heredoc_end.absent? >> heredoc_line).repeat }
    rule(:heredoc_line) { (line_break.absent? >> heredoc_content_any).repeat >> line_break.as(:character) }
    rule(:heredoc_content_any) { escape_sequence.as(:character) | any.as(:character) }

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
