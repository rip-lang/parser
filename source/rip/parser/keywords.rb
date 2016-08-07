module Rip::Parser
  class Keyword
    attr_reader :name
    attr_reader :source_text

    def initialize(name, source_text = name)
      @name = name.to_sym
      @source_text = source_text.to_s
    end

    def ==(other)
      name == other.name
    end

    def to_debug
      name
    end

    def self.[](name)
      Keywords.all.detect do |keyword|
        keyword.name == name
      end.tap do |keyword|
        raise "Unknown keyword: `#{name}`" if keyword.nil?
      end
    end
  end

  module Keywords
    def self.all
      [
        conditional,
        dependency,
        exceptional,
        object,
        pseudo,
        query,
        transfer
      ].inject(&:+)
    end

    def self.conditional
      make_keywords(:if, :switch, :case, :else)
    end

    def self.dependency
      make_keywords(:import)
    end

    def self.exceptional
      make_keywords(:try, :catch, :finally)
    end

    def self.object
      [
        *make_keywords(:class, :enum, :interface),
        Keyword.new(:swerve_rocket, '~>'),
        Keyword.new(:dash_rocket, '->'),
        Keyword.new(:fat_rocket, '=>')
      ]
    end

    def self.pseudo
      [
        Keyword.new(:class_self, 'self'),
        Keyword.new(:class_prototype, '@'),
        Keyword.new(:lambda_receiver, '@')
      ]
    end

    def self.query
      make_keywords(:from, :as, :join, :union, :on, :where, :order, :select, :limit, :take)
    end

    def self.transfer
      make_keywords(:exit, :return, :throw)
    end

    protected

    def self.make_keywords(*names)
      names.map { |name| Keyword.new(name) }
    end
  end
end
