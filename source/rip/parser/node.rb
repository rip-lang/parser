module Rip::Parser
  class Node
    include Enumerable

    attr_reader :location
    attr_reader :type
    attr_reader :extra

    def initialize(location:, type:, **extra)
      @location = location
      @type = type
      @extra = extra.inject({}) do |memo, (key, value)|
        memo.merge(key => self.class.try_convert(value))
      end
    end

    def ==(other)
      to_h == other.to_h
    end

    def [](key)
      case key.to_sym
        when :location then location
        when :type     then type
        else                extra[key.to_sym]
      end
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

    def s_expression
      _extra = extra.map do |key, value|
        [ key, self.class.try_convert_s_expression(value) ]
      end.to_h

      { type: type }.merge(_extra)
    end

    def to_h
      _extra = extra.map do |key, value|
        [ key, self.class.try_convert_to_h(value) ]
      end.to_h

      { location: location, type: type }.merge(_extra)
    end

    def traverse(&callback)
      _extra = extra.map do |key, value|
        _value = case value
        when Array
          value.map do |v|
            v.traverse(&callback)
          end
        when self.class
          value.traverse(&callback)
        else
          value
        end

        [ key, _value ]
      end.to_h

      callback.call(merge(_extra))
    end

    private

    def method_missing(missing_method, *args, &block)
      case
      when key?(missing_method)
        extra[missing_method]
      when missing_method.to_s.end_with?('?')
        missing_method.to_s.sub(/\?\z/, '').to_sym == type
      else
        super
      end
    end

    def respond_to_missing?(name, include_all)
      key?(name) || name.to_s.end_with?('?')
    end

    def self.try_convert(value)
      case value
      when Array
        value.map(&method(:try_convert))
      when Hash
        new(value)
      else
        value
      end
    end

    def self.try_convert_to_h(value)
      case value
      when Array
        value.map(&method(:try_convert_to_h))
      when self
        value.to_h
      else
        value
      end
    end

    def self.try_convert_s_expression(value)
      case value
      when Array
        value.map(&method(:try_convert_s_expression))
      when self
        value.s_expression
      else
        value
      end
    end
  end
end
