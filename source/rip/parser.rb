module Rip
  module Parser
    def self.tree(origin, source_code)
      Rip::Parser::Normalizer.apply(raw_tree(origin, source_code))
    end

    def self.raw_tree(origin, source_code)
      begin
        rules.parse(source_code)
      rescue Parslet::ParseFailed => e
        location = Rip::Parser::Location.new(origin, e.cause.pos, *e.cause.source.line_and_column)
        raise Rip::Exceptions::SyntaxError.new(e.message, location, [], e.cause.ascii_tree)
      end
    end

    def self.rules
      Rip::Parser::Rules.new
    end
  end
end

require_relative './parser/about'
require_relative './parser/keywords'
require_relative './parser/location'
require_relative './parser/normalizer'
require_relative './parser/rules'
