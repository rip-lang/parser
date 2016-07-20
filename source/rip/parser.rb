require 'hashie'

module Rip
  module Parser
    def self.load_file(module_path)
      tree(Pathname.new(module_path).expand_path, Pathname.new(module_path).read)
    end

    def self.root
      Pathname.new(__dir__).parent.parent
    end

    def self.tree(origin, source_code)
      reply = Rip::Parser::Grammar.parse(origin, source_code)
      Hashie::Mash.new(reply)
    end
  end
end

require_relative './parser/about'
require_relative './parser/grammar'
require_relative './parser/keywords'
require_relative './parser/location'
require_relative './parser/rules'
