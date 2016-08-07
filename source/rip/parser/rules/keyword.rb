require 'parslet'

module Rip::Parser::Rules
  module Keyword
    include ::Parslet

    def keyword(word)
      keyword = Rip::Parser::Keyword[word]
      str(keyword.source_text).as(keyword.name)
    end
  end
end
