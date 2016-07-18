require 'hashie'

module Rip
  module Parser
    def self.load_file(module_path)
      tree(module_path.expand_path, module_path.read)
    end

    def self.root
      Pathname.new(__dir__).parent.parent
    end

    def self.tree(origin, source_code)
      reply = Rip::Parser::Normalizer.apply(raw_tree(origin, source_code))
      Hashie::Mash.new(reply)
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
