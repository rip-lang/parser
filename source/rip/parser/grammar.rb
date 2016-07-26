require 'parslet'

require_relative './rules'

module Rip::Parser
  class Grammar
    include Rip::Parser::Rules::Module

    def self.parse(origin, source_code)
      begin
        raw_tree = new.module.parse(source_code)
        Rip::Parser::Utilities::Normalizer.apply(origin, raw_tree)
      rescue Parslet::ParseFailed => e
        match = /\A.+ at line (\d+) char (\d+)\.\z/.match(e.message)
        line, column = match ? match.values_at(1, 2).map(&:to_i) : [ 0, 0 ]
        location = Rip::Parser::Location.new(origin, e.cause.pos.charpos, line, column)
        raise Rip::Parser::SyntaxError.new(e.message, location, e.cause)
      end
    end
  end
end

require_relative './utilities/normalizer'
