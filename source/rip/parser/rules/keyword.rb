require 'parslet'

module Rip::Parser::Rules
  module Keyword
    include ::Parslet

    def keyword(word)
      str(word.to_s).as(word.to_sym)
    end
  end
end
