module Rip::Parser
  class Location
    attr_reader :origin  # label where source code is coming from
    attr_reader :offset  # zero-based offset from begining of file
    attr_reader :line    # one-based line number
    attr_reader :column  # one-based character on line
    attr_reader :length  # how many characters are covered

    def initialize(origin, offset, line, column, length = 0)
      @origin = origin
      @offset = offset
      @line = line
      @column = column
      @length = length
    end

    def ==(other)
      (origin == other.origin) &&
        (offset == other.offset)
    end

    def add_character(count = 1)
      self.class.new(origin, offset + count, line, column + count, length)
    end

    def add_line(count = 1)
      self.class.new(origin, offset + count, line + count, 1, length)
    end

    def inspect
      "#<#{self.class.name} #{self}>"
    end

    def to_s
      "#{origin}:#{to_debug}"
    end

    def to_debug
      offset_length = length.zero? ? offset : (offset..(offset + length - 1))
      "#{line}:#{column}(#{offset_length})"
    end

    def self.from_slice(origin, slice, length = slice.length)
      new(origin, slice.offset, *slice.line_and_column, length)
    end
  end
end
