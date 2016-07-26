require 'parslet'

require_relative './common'
require_relative './keyword'
require_relative './string'

module Rip::Parser::Rules
  module Import
    include ::Parslet

    include Rip::Parser::Rules::Common
    include Rip::Parser::Rules::Keyword
    include Rip::Parser::Rules::String

    rule(:import) { keyword(:import) >> (import_bare | import_parens) }

    rule(:import_bare) { spaces >> module_name }

    rule(:import_parens) { parenthesis_open >> module_name >> spaces? >> parenthesis_close }

    rule(:module_name) { spaces? >> (string_symbol | string_double).as(:module_name) }
  end
end
