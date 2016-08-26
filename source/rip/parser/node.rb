module Rip::Parser
  class Node
    include Enumerable

    attr_reader :location
    attr_reader :type
    attr_reader :extra

    def initialize(location:, type:, **extra)
      @location = location
      @type = type
      @extra = extra
    end

    def ==(other)
      to_h == other.to_h
    end

    def [](key)
      to_h[key.to_sym]
    end

    def each(&block)
      to_h.each(&block)
    end

    def key?(key)
      extra.key?(key.to_sym)
    end

    def keys
      extra.keys
    end

    def length
      location.length
    end

    def merge(other)
      self.class.new(extra.merge(other.to_h).merge(location: location, type: other[:type] || type))
    end

    def to_h
      { location: location, type: type }.merge(extra)
    end

    private

    def method_missing(missing_method, *args, &block)
      case
      when key?(missing_method)
        self[missing_method]
      when missing_method.to_s.end_with?('?')
        missing_method.to_s.sub(/\?\z/, '').to_sym == type
      else
        super
      end
    end

    def respond_to_missing?(name, include_all)
      key?(name) || name.to_s.end_with?('?')
    end
  end
end
