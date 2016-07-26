require 'hashie'

module Rip
  module Parser
    def self.load(origin, source_code)
      tree = Rip::Parser::Grammar.parse(origin, source_code)
      Hashie::Mash.new(tree)
    end

    def self.load_file(module_path)
      _module_path = Pathname.new(module_path).expand_path
      load(_module_path, _module_path.read)
    end

    def self.root
      Pathname.new(__dir__).parent.parent
    end
  end
end

require_relative './parser/about'
require_relative './parser/error'
require_relative './parser/grammar'
require_relative './parser/keywords'
require_relative './parser/location'
require_relative './parser/rules'
