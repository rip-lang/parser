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
        location = Rip::Parser::Location.from_slice(origin, e.cause)
        raise Rip::Exceptions::SyntaxError.new(e.message, location, [], e.cause.ascii_tree)
      end
    end
  end
end

require_relative './utilities/normalizer'
