module Rip::Parser
  class Node
    attr_reader :location
    attr_reader :parent
    attr_reader :type
    attr_reader :extra

    def initialize(location:, parent: nil, type:, **extra)
      @location = location
      @parent = parent
      @type = type
      @extra = extra.inject({}) do |memo, (key, value)|
        memo.merge(key => self.class.try_convert(value, self))
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

    def key?(key)
      extra.key?(key.to_sym)
    end

    def keys
      extra.keys
    end

    def values
      extra.values
    end

    def length
      location.length
    end

    def merge(other)
      self.class.new(extra.merge(other.to_h).merge(location: location, type: other[:type] || type))
    end

    def to_h(include_location: true)
      _extra = extra.map do |key, value|
        [ key, self.class.try_convert_to_h(value, include_location) ]
      end.to_h

      if include_location
        { location: location, type: type }
      else
        { type: type }
      end.merge(_extra)
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

      callback.call(merge(_extra.merge(parent: parent)))
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

    def self.try_convert(value, parent)
      case value
      when Array
        value.map do |v|
          try_convert(v, parent)
        end
      when Hash
        new(value.merge(parent: parent))
      when self
        new(value.to_h.merge(parent: parent))
      else
        value
      end
    end

    def self.try_convert_to_h(value, include_location)
      case value
      when Array
        value.map do |v|
          try_convert_to_h(v, include_location)
        end
      when self
        value.to_h(include_location: include_location)
      else
        value
      end
    end
  end
end
