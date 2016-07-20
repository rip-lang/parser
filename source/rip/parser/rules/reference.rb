require 'parslet'

require_relative './number'

module Rip::Parser::Rules
  module Reference
    include ::Parslet

    include Rip::Parser::Rules::Number

    rule(:reference) { word.as(:reference) }

    rule(:word) { word_legal >> (word_legal | digit).repeat }
    rule(:word_legal) { match['^\d\s\`\'",.:;#\/\\()<>\[\]{}'] }
  end
end
