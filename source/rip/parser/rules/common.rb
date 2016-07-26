require 'parslet'

module Rip::Parser::Rules
  module Common
    include ::Parslet

    rule(:whitespace) { space | line_break | comment }
    rule(:whitespaces) { whitespace.repeat(1) }
    rule(:whitespaces?) { whitespaces.maybe }

    rule(:space) { str(' ') | str("\t") }
    rule(:spaces) { space.repeat(1) }
    rule(:spaces?) { spaces.maybe }

    rule(:line_break) { str("\r\n") | str("\n") | str("\r") }
    rule(:line_breaks) { line_break.repeat(1) }
    rule(:line_breaks?) { line_breaks.maybe }

    rule(:comment) { pound >> (line_break.absent? >> any).repeat >> (line_break | eof) }

    rule(:eof) { any.absent? }

    rule(:dot) { str('.') }
    rule(:comma) { str(',') }
    rule(:semicolon) { str(';') }
    rule(:colon) { str(':') }
    rule(:pound) { str('#') }
    rule(:dash) { str('-') }
    rule(:underscore) { str('_') }
    rule(:equals) { str('=') }

    rule(:slash_back) { str('\\') }
    rule(:slash_forward) { str('/') }

    rule(:angled_open) { str('<') }
    rule(:angled_close) { str('>') }

    rule(:brace_open) { str('{') }
    rule(:brace_close) { str('}') }

    rule(:bracket_open) { str('[') }
    rule(:bracket_close) { str(']') }

    rule(:parenthesis_open) { str('(') }
    rule(:parenthesis_close) { str(')') }
  end
end
