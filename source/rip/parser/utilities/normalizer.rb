require 'hashie'
require 'parslet'

module Rip::Parser::Utilities
  class Normalizer < Parslet::Transform
    def apply(raw_tree, context = nil)
      super(raw_tree, context)
    end

    def self.apply(origin, raw_tree)
      new.apply(raw_tree, origin: origin).tap do |tree|
        validate(tree, origin)
      end
    end

    def self.validate(tree, origin)
      case tree
      when Array
        tree.each do |branch|
          validate(branch, origin)
        end
      when Hash, Hashie::Mash
        tree.each_value do |branch|
          validate(branch, origin)
        end

        if tree.key?(:expression_chain)
          shape = tree[:expression_chain].map do |key, value|
            [ key, value.class ]
          end.to_h
          warn shape
          raise Rip::Parser::NormalizeError.new('Unhandled expression_chain node', origin, tree)
        end
      end
    end


    rule(expression_chain: simple(:part)) do |part:, origin:|
      part
    end

    rule(expression_chain: sequence(:parts)) do |parts:, origin:|
      parts.inject do |base, link|
        case
          when link.key?(:property_name)   then link.merge(object: base)
          when link.key?(:value)           then link.merge(key: base)
          when link.key?(:end)             then link.merge(start: base)
          when link.key?(:arguments)       then link.merge(callable: base)
          when link.key?(:index_arguments)
            Hashie::Mash.new(
              callable: {
                object: base,
                property_name: '[]'
              },
              arguments: link.index_arguments,
              location: link.location
            )
          else
            warn link
            raise Rip::Parser::NormalizeError.new('Unhandled expression link node', origin, link)
        end
      end
    end

    rule(lhs: simple(:lhs), location: simple(:location), rhs: simple(:rhs)) do |lhs:, location:, rhs:, origin:|
      Hashie::Mash.new(
        lhs: lhs,
        rhs: rhs,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + rhs.location.offset - location.offset)
      )
    end

    rule(location: simple(:location), property_name: simple(:property_name)) do |location:, property_name:, origin:|
      Hashie::Mash.new(
        property_name: property_name.to_s,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + property_name.offset - location.offset)
      )
    end

    rule(location: simple(:location), value: simple(:value)) do |location:, value:, origin:|
      Hashie::Mash.new(
        value: value,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + value.location.length)
      )
    end

    rule(location: simple(:location), end: simple(:_end)) do |location:, _end:, origin:|
      Hashie::Mash.new(
        end: _end,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + _end.location.length)
      )
    end

    rule(location: simple(:location), arguments: sequence(:arguments)) do |location:, arguments:, origin:|
      Hashie::Mash.new(
        arguments: arguments,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + arguments.map(&:location).map(&:length).inject(0, &:+))
      )
    end

    rule(location: simple(:location), index_arguments: sequence(:arguments)) do |location:, arguments:, origin:|
      Hashie::Mash.new(
        index_arguments: arguments,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + arguments.map(&:location).map(&:length).inject(0, &:+))
      )
    end


    rule(module: simple(:expression)) do |expression:, origin:|
      Hashie::Mash.new(
        module: [ expression ],
        location: Rip::Parser::Location.new(origin, 0, 0, 0)
      )
    end

    rule(module: sequence(:expressions)) do |expressions:, origin:|
      Hashie::Mash.new(
        module: expressions,
        location: Rip::Parser::Location.new(origin, 0, 0, 0)
      )
    end


    rule(import: simple(:location), module_name: simple(:module_name)) do |location:, module_name:, origin:|
      Hashie::Mash.new(
        module_name: module_name,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + module_name.location.offset - location.offset)
      )
    end


    rule(integer: simple(:integer)) do |integer:, origin:|
      Hashie::Mash.new(
        sign: :+,
        integer: integer.to_s,
        location: Rip::Parser::Location.from_slice(origin, integer, integer.length)
      )
    end

    rule(integer: simple(:integer), decimal: simple(:decimal)) do |integer:, decimal:, origin:|
      Hashie::Mash.new(
        sign: :+,
        integer: integer.to_s,
        decimal: decimal.to_s,
        location: Rip::Parser::Location.from_slice(origin, integer, integer.length + decimal.length)
      )
    end

    rule(sign: simple(:sign), integer: simple(:integer)) do |sign:, integer:, origin:|
      Hashie::Mash.new(
        sign: sign.to_sym,
        integer: integer.to_s,
        location: Rip::Parser::Location.from_slice(origin, sign, sign.length + integer.length)
      )
    end

    rule(sign: simple(:sign), integer: simple(:integer), decimal: simple(:decimal)) do |sign:, integer:, decimal:, origin:|
      Hashie::Mash.new(
        sign: sign.to_sym,
        integer: integer.to_s,
        decimal: decimal.to_s,
        location: Rip::Parser::Location.from_slice(origin, sign, sign.length + integer.length + decimal.length)
      )
    end


    rule(escape_unicode: simple(:sequence), escape_location: simple(:escape_location)) do |sequence:, escape_location:, origin:|
      Hashie::Mash.new(
        escape_unicode: sequence.to_s,
        location: Rip::Parser::Location.from_slice(origin, escape_location, escape_location.length + sequence.length)
      )
    end

    rule(escape_unicode: simple(:sequence), escape_location: simple(:escape_location), location: simple(:location)) do |sequence:, location:, escape_location:, origin:|
      Hashie::Mash.new(
        escape_unicode: sequence.to_s,
        location: Rip::Parser::Location.from_slice(origin, location, [ location, escape_location, sequence ].map(&:length).inject(&:+))
      )
    end


    rule(escape_special: simple(:sequence), escape_location: simple(:escape_location)) do |sequence:, escape_location:, origin:|
      Hashie::Mash.new(
        escape_special: sequence.to_s,
        location: Rip::Parser::Location.from_slice(origin, escape_location, escape_location.length + sequence.length)
      )
    end

    rule(escape_special: simple(:sequence), escape_location: simple(:escape_location), location: simple(:location)) do |sequence:, location:, escape_location:, origin:|
      Hashie::Mash.new(
        escape_special: sequence.to_s,
        location: Rip::Parser::Location.from_slice(origin, location, [ location, escape_location, sequence ].map(&:length).inject(&:+))
      )
    end


    rule(escape_any: simple(:sequence), escape_location: simple(:escape_location)) do |sequence:, escape_location:, origin:|
      Hashie::Mash.new(
        escape_any: sequence.to_s,
        location: Rip::Parser::Location.from_slice(origin, escape_location, escape_location.length + sequence.length)
      )
    end

    rule(escape_any: simple(:sequence), escape_location: simple(:escape_location), location: simple(:location)) do |sequence:, location:, escape_location:, origin:|
      Hashie::Mash.new(
        escape_any: sequence.to_s,
        location: Rip::Parser::Location.from_slice(origin, location, [ location, escape_location, sequence ].map(&:length).inject(&:+))
      )
    end


    rule(character: simple(:character)) do |character:, origin:|
      Hashie::Mash.new(
        character: character.to_s,
        location: Rip::Parser::Location.from_slice(origin, character, character.length)
      )
    end

    rule(character: simple(:character), location: simple(:location)) do |character:, location:, origin:|
      Hashie::Mash.new(
        character: character.to_s,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + character.length)
      )
    end


    rule(regular_expression: sequence(:characters), location: simple(:location)) do |characters:, location:, origin:|
      length = characters.inject(location.length + 1) do |memo, character|
        memo + character.location.length
      end

      Hashie::Mash.new(
        regular_expression: characters,
        location: Rip::Parser::Location.from_slice(origin, location, length)
      )
    end


    rule(string: sequence(:characters), location: simple(:location)) do |characters:, location:, origin:|
      closing_delimiter_length = case location
        when /:/                       then 0
        when /"/                       then 1
        when /\A\<\<(?<label>[A-Z_]+)/ then Regexp.last_match(:label).length
      end

      length = characters.inject(location.length + closing_delimiter_length) do |memo, character|
        memo + character.location.length
      end

      Hashie::Mash.new(
        string: characters,
        location: Rip::Parser::Location.from_slice(origin, location, length)
      )
    end


    rule(list: sequence(:items), location: simple(:location)) do |items:, location:, origin:|
      length = items.inject(location.length) do |memo, item|
        memo + item.location.length
      end

      Hashie::Mash.new(
        list: items,
        location: Rip::Parser::Location.from_slice(origin, location, length)
      )
    end

    rule(map: sequence(:pairs), location: simple(:location)) do |pairs:, location:, origin:|
      length = pairs.inject(location.length) do |memo, pair|
        memo + pair.location.length
      end

      Hashie::Mash.new(
        map: pairs,
        location: Rip::Parser::Location.from_slice(origin, location, length)
      )
    end


    rule(reference: simple(:reference)) do |reference:, origin:|
      Hashie::Mash.new(
        reference: reference.to_s,
        location: Rip::Parser::Location.from_slice(origin, reference)
      )
    end


    rule(dash_rocket: simple(:location), body: simple(:expression)) do |location:, expression:, origin:|
      Hashie::Mash.new(
        parameters: [],
        body: [ expression ],
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end

    rule(dash_rocket: simple(:location), parameters: sequence(:parameters), body: simple(:expression)) do |location:, parameters:, expression:, origin:|
      Hashie::Mash.new(
        parameters: parameters,
        body: [ expression ],
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end

    rule(dash_rocket: simple(:location), body: sequence(:body)) do |location:, body:, origin:|
      Hashie::Mash.new(
        parameters: [],
        body: body,
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end

    rule(dash_rocket: simple(:location), parameters: sequence(:parameters), body: sequence(:body)) do |location:, parameters:, body:, origin:|
      Hashie::Mash.new(
        parameters: parameters,
        body: body,
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end

    rule(parameter: simple(:parameter)) do |parameter:, origin:|
      Hashie::Mash.new(
        parameter: parameter.to_s,
        location: Rip::Parser::Location.from_slice(origin, parameter)
      )
    end


    rule(fat_rocket: simple(:location), overloads: sequence(:overloads)) do |location:, overloads:, origin:|
      Hashie::Mash.new(
        overloads: overloads,
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end
  end
end
