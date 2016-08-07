module Rip::Parser
  class Error < StandardError
    attr_reader :code

    def initialize(message)
      super
      @code = 10
    end
  end

  class SyntaxError < Error
    attr_reader :location
    attr_reader :cause

    def initialize(message, location, cause)
      super(message)

      @location = location
      @cause = cause
      @code = 11
    end
  end

  class NormalizeError < Error
    attr_reader :origin
    attr_reader :tree

    def initialize(message, origin, tree = nil)
      super(message)

      @origin = origin
      @tree = tree
      @code = 12
    end
  end
end
