require 'parslet'

module Rip::Parser::Utilities
  class Normalizer < Parslet::Transform
    def apply(raw_tree, context = nil)
      super(raw_tree, context)
    end

    def self.apply(origin, raw_tree)
      new.apply(raw_tree, origin: origin)
    end
  end
end
