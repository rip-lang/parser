require 'parslet'

module Rip::Parser::Utilities
  class Normalizer < Parslet::Transform
    def apply(raw_tree, context = nil)
      super(raw_tree, context)
    end

    def self.apply(origin, raw_tree)
      new.apply(raw_tree, origin: origin).tap do |tree|
        validate_branches(tree, origin)
        validate_leaves(tree, origin)
      end
    end

    def self.validate_branches(tree, origin)
      case tree
      when Array
        tree.each do |branch|
          validate_branches(branch, origin)
        end
      when Hash, Rip::Parser::Node
        tree.each do |_, branch|
          validate_branches(branch, origin)
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

    def self.validate_leaves(tree, origin)
      case tree
      when Array
        tree.each do |branch|
          validate_leaves(branch, origin)
        end
      when Rip::Parser::Node
        tree.each do |_, branch|
          validate_leaves(branch, origin)
        end
      when Parslet::Slice
        warn tree
        raise Rip::Parser::NormalizeError.new('Unconverted parslet slice', origin, tree)
      end
    end


    rule(expression_chain: simple(:part)) do |part:, origin:|
      part
    end

    rule(expression_chain: sequence(:parts)) do |parts:, origin:|
      parts.inject do |base, link|
        case
          when link.property_access?  then link.merge(object: base)
          when link.pair_value?       then link.merge(type: :pair, key: base)
          when link.range_end?        then link.merge(type: :range, start: base)
          when link.invocation?       then link.merge(callable: base)
          when link.invocation_index?
            Rip::Parser::Node.new(
              type: :invocation_index,
              callable: {
                type: :property_access,
                object: base,
                property_name: '[]',
                location: link.location
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
      Rip::Parser::Node.new(
        type: :assignment,
        lhs: lhs,
        rhs: rhs,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + rhs.location.offset - location.offset)
      )
    end

    rule(location: simple(:location), property_name: simple(:property_name)) do |location:, property_name:, origin:|
      Rip::Parser::Node.new(
        type: :property_access,
        property_name: property_name.to_s,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + property_name.offset - location.offset)
      )
    end

    rule(object: simple(:object), location: simple(:location), property_name: simple(:property_name)) do |object:, location:, property_name:, origin:|
      Rip::Parser::Node.new(
        type: :property_access,
        object: object,
        property_name: property_name.to_s,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + property_name.offset - location.offset)
      )
    end

    rule(location: simple(:location), value: simple(:value)) do |location:, value:, origin:|
      Rip::Parser::Node.new(
        type: :pair_value,
        value: value,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + value.location.length)
      )
    end

    rule(location: simple(:location), end: simple(:_end)) do |location:, _end:, origin:|
      Rip::Parser::Node.new(
        type: :range_end,
        end: _end,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + _end.location.length)
      )
    end

    rule(location: simple(:location), arguments: sequence(:arguments)) do |location:, arguments:, origin:|
      Rip::Parser::Node.new(
        type: :invocation,
        arguments: arguments,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + arguments.map(&:location).map(&:length).inject(0, &:+))
      )
    end

    rule(location: simple(:location), index_arguments: sequence(:arguments)) do |location:, arguments:, origin:|
      Rip::Parser::Node.new(
        type: :invocation_index,
        index_arguments: arguments,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + arguments.map(&:location).map(&:length).inject(0, &:+))
      )
    end


    rule(module: simple(:expression)) do |expression:, origin:|
      Rip::Parser::Node.new(
        type: :module,
        expressions: [ expression ],
        location: Rip::Parser::Location.new(origin, 0, 0, 0)
      )
    end

    rule(module: sequence(:expressions)) do |expressions:, origin:|
      Rip::Parser::Node.new(
        type: :module,
        expressions: expressions,
        location: Rip::Parser::Location.new(origin, 0, 0, 0)
      )
    end


    rule(import: simple(:location), module_name: simple(:module_name)) do |location:, module_name:, origin:|
      Rip::Parser::Node.new(
        type: :import,
        module_name: module_name,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + module_name.location.offset - location.offset)
      )
    end


    rule(date: simple(:date), time: simple(:time)) do |date:, time:, origin:|
      Rip::Parser::Node.new(
        type: :date_time,
        date: date,
        time: time,
        location: date.location.add_character(1 + time.length)
      )
    end

    rule(year: simple(:year), month: simple(:month), day: simple(:day)) do |year:, month:, day:, origin:|
      Rip::Parser::Node.new(
        type: :date,
        year: year.to_s,
        month: month.to_s,
        day: day.to_s,
        location: Rip::Parser::Location.from_slice(origin, year + '-' + month + '-' + day)
      )
    end

    rule(hour: simple(:hour), minute: simple(:minute), second: simple(:second)) do |hour:, minute:, second:, origin:|
      Rip::Parser::Node.new(
        type: :time,
        hour: hour.to_s,
        minute: minute.to_s,
        second: second.to_s,
        location: Rip::Parser::Location.from_slice(origin, hour + '-' + minute + '-' + second)
      )
    end

    rule(hour: simple(:hour), minute: simple(:minute), second: simple(:second), sub_second: simple(:sub_second)) do |hour:, minute:, second:, sub_second:, origin:|
      Rip::Parser::Node.new(
        type: :time,
        hour: hour.to_s,
        minute: minute.to_s,
        second: second.to_s,
        sub_second: sub_second.to_s,
        location: Rip::Parser::Location.from_slice(origin, hour + '-' + minute + '-' + second + '.' + sub_second)
      )
    end

    rule(hour: simple(:hour), minute: simple(:minute), second: simple(:second), offset: simple(:offset)) do |hour:, minute:, second:, offset:, origin:|
      slice = hour + '-' + minute + '-' + second

      Rip::Parser::Node.new(
        type: :time,
        hour: hour.to_s,
        minute: minute.to_s,
        second: second.to_s,
        offset: offset,
        location: Rip::Parser::Location.from_slice(origin, slice, slice.length + offset.length)
      )
    end

    rule(hour: simple(:hour), minute: simple(:minute), second: simple(:second), sub_second: simple(:sub_second), offset: simple(:offset)) do |hour:, minute:, second:, sub_second:, offset:, origin:|
      slice = hour + '-' + minute + '-' + second + '.' + sub_second

      Rip::Parser::Node.new(
        type: :time,
        hour: hour.to_s,
        minute: minute.to_s,
        second: second.to_s,
        sub_second: sub_second.to_s,
        offset: offset,
        location: Rip::Parser::Location.from_slice(origin, slice, slice.length + offset.length)
      )
    end

    rule(sign: simple(:sign), hour: simple(:hour), minute: simple(:minute)) do |sign:, hour:, minute:, origin:|
      Rip::Parser::Node.new(
        type: :time_offset,
        sign: sign.to_sym,
        hour: hour.to_s,
        minute: minute.to_s,
        location: Rip::Parser::Location.from_slice(origin, sign + hour + minute)
      )
    end


    rule(magnitude: simple(:magnitude), label: simple(:label)) do |magnitude:, label:, origin:|
      Rip::Parser::Node.new(
        type: :unit,
        magnitude: magnitude,
        label: label.to_s,
        location: magnitude.location.add_character(label.length)
      )
    end


    rule(integer: simple(:integer)) do |integer:, origin:|
      Rip::Parser::Node.new(
        type: :integer,
        sign: :+,
        integer: integer.to_s,
        location: Rip::Parser::Location.from_slice(origin, integer, integer.length)
      )
    end

    rule(integer: simple(:integer), decimal: simple(:decimal)) do |integer:, decimal:, origin:|
      Rip::Parser::Node.new(
        type: :decimal,
        sign: :+,
        integer: integer.to_s,
        decimal: decimal.to_s,
        location: Rip::Parser::Location.from_slice(origin, integer, integer.length + decimal.length)
      )
    end

    rule(sign: simple(:sign), integer: simple(:integer)) do |sign:, integer:, origin:|
      Rip::Parser::Node.new(
        type: :integer,
        sign: sign.to_sym,
        integer: integer.to_s,
        location: Rip::Parser::Location.from_slice(origin, sign, sign.length + integer.length)
      )
    end

    rule(sign: simple(:sign), integer: simple(:integer), decimal: simple(:decimal)) do |sign:, integer:, decimal:, origin:|
      Rip::Parser::Node.new(
        type: :decimal,
        sign: sign.to_sym,
        integer: integer.to_s,
        decimal: decimal.to_s,
        location: Rip::Parser::Location.from_slice(origin, sign, sign.length + integer.length + decimal.length)
      )
    end


    rule(escape_unicode: simple(:sequence), escape_location: simple(:escape_location)) do |sequence:, escape_location:, origin:|
      Rip::Parser::Node.new(
        type: :escape_unicode,
        sequence: sequence.to_s,
        location: Rip::Parser::Location.from_slice(origin, escape_location, escape_location.length + sequence.length)
      )
    end

    rule(escape_unicode: simple(:sequence), escape_location: simple(:escape_location), location: simple(:location)) do |sequence:, location:, escape_location:, origin:|
      Rip::Parser::Node.new(
        type: :escape_unicode,
        sequence: sequence.to_s,
        location: Rip::Parser::Location.from_slice(origin, location, [ location, escape_location, sequence ].map(&:length).inject(&:+))
      )
    end


    rule(escape_special: simple(:sequence), escape_location: simple(:escape_location)) do |sequence:, escape_location:, origin:|
      Rip::Parser::Node.new(
        type: :escape_special,
        sequence: sequence.to_s,
        location: Rip::Parser::Location.from_slice(origin, escape_location, escape_location.length + sequence.length)
      )
    end

    rule(escape_special: simple(:sequence), escape_location: simple(:escape_location), location: simple(:location)) do |sequence:, location:, escape_location:, origin:|
      Rip::Parser::Node.new(
        type: :escape_special,
        sequence: sequence.to_s,
        location: Rip::Parser::Location.from_slice(origin, location, [ location, escape_location, sequence ].map(&:length).inject(&:+))
      )
    end


    rule(escape_any: simple(:sequence), escape_location: simple(:escape_location)) do |sequence:, escape_location:, origin:|
      Rip::Parser::Node.new(
        type: :escape_any,
        sequence: sequence.to_s,
        location: Rip::Parser::Location.from_slice(origin, escape_location, escape_location.length + sequence.length)
      )
    end

    rule(escape_any: simple(:sequence), escape_location: simple(:escape_location), location: simple(:location)) do |sequence:, location:, escape_location:, origin:|
      Rip::Parser::Node.new(
        type: :escape_any,
        sequence: sequence.to_s,
        location: Rip::Parser::Location.from_slice(origin, location, [ location, escape_location, sequence ].map(&:length).inject(&:+))
      )
    end


    rule(character: simple(:character)) do |character:, origin:|
      Rip::Parser::Node.new(
        type: :character,
        data: character.to_s,
        location: Rip::Parser::Location.from_slice(origin, character, character.length)
      )
    end

    rule(character: simple(:character), location: simple(:location)) do |character:, location:, origin:|
      Rip::Parser::Node.new(
        type: :character,
        data: character.to_s,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + character.length)
      )
    end


    rule(regular_expression: sequence(:characters), location: simple(:location)) do |characters:, location:, origin:|
      length = characters.inject(location.length + 1) do |memo, character|
        memo + character.location.length
      end

      Rip::Parser::Node.new(
        type: :regular_expression,
        pattern: characters,
        location: Rip::Parser::Location.from_slice(origin, location, length)
      )
    end


    rule(interpolation: simple(:expression), location: simple(:location)) do |expression:, location:, origin:|
      Rip::Parser::Node.new(
        type: :interpolation,
        expression: expression,
        location: Rip::Parser::Location.from_slice(origin, location, location.length + expression.length)
      )
    end


    rule(string: sequence(:characters), location: simple(:location)) do |characters:, location:, origin:|
      closing_delimiter_length = case location
        when /:/ then 0
        when /"/ then 1
      end

      length = characters.inject(location.length + closing_delimiter_length) do |memo, character|
        memo + character.location.length
      end

      Rip::Parser::Node.new(
        type: :string,
        characters: characters,
        location: Rip::Parser::Location.from_slice(origin, location, length)
      )
    end

    rule(string: sequence(:characters), label: simple(:label), location: simple(:location)) do |characters:, label:, location:, origin:|
      length = characters.inject(location.length + (label.length * 2) + 1) do |memo, character|
        memo + character.location.length
      end

      Rip::Parser::Node.new(
        type: :string,
        label: label.to_s,
        characters: characters,
        location: Rip::Parser::Location.from_slice(origin, location, length)
      )
    end


    rule(list: sequence(:items), location: simple(:location)) do |items:, location:, origin:|
      length = items.inject(location.length) do |memo, item|
        memo + item.location.length
      end

      Rip::Parser::Node.new(
        type: :list,
        items: items,
        location: Rip::Parser::Location.from_slice(origin, location, length)
      )
    end

    rule(map: sequence(:pairs), location: simple(:location)) do |pairs:, location:, origin:|
      length = pairs.inject(location.length) do |memo, pair|
        memo + pair.location.length
      end

      Rip::Parser::Node.new(
        type: :map,
        pairs: pairs,
        location: Rip::Parser::Location.from_slice(origin, location, length)
      )
    end


    rule(reference: simple(:reference)) do |reference:, origin:|
      Rip::Parser::Node.new(
        type: :reference,
        name: reference.to_s,
        location: Rip::Parser::Location.from_slice(origin, reference)
      )
    end


    rule(dash_rocket: simple(:location), body: simple(:expression)) do |location:, expression:, origin:|
      Rip::Parser::Node.new(
        type: :overload,
        parameters: [],
        body: [ expression ],
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end

    rule(dash_rocket: simple(:location), parameters: sequence(:parameters), body: simple(:expression)) do |location:, parameters:, expression:, origin:|
      Rip::Parser::Node.new(
        type: :overload,
        parameters: parameters,
        body: [ expression ],
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end

    rule(dash_rocket: simple(:location), body: sequence(:body)) do |location:, body:, origin:|
      Rip::Parser::Node.new(
        type: :overload,
        parameters: [],
        body: body,
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end

    rule(dash_rocket: simple(:location), parameters: sequence(:parameters), body: sequence(:body)) do |location:, parameters:, body:, origin:|
      Rip::Parser::Node.new(
        type: :overload,
        parameters: parameters,
        body: body,
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end


    rule(parameter: simple(:parameter)) do |parameter:, origin:|
      Rip::Parser::Node.new(
        type: :required_parameter,
        name: parameter.to_s,
        location: Rip::Parser::Location.from_slice(origin, parameter)
      )
    end

    rule(parameter: simple(:parameter), type_argument: simple(:type_argument)) do |parameter:, type_argument:, origin:|
      Rip::Parser::Node.new(
        type: :required_parameter,
        name: parameter.to_s,
        type_argument: type_argument,
        location: Rip::Parser::Location.from_slice(origin, parameter)
      )
    end

    rule(parameter: simple(:parameter), default: simple(:default)) do |parameter:, default:, origin:|
      Rip::Parser::Node.new(
        type: :optional_parameter,
        name: parameter.to_s,
        default: default,
        location: Rip::Parser::Location.from_slice(origin, parameter)
      )
    end

    rule(parameter: simple(:parameter), type_argument: simple(:type_argument), default: simple(:default)) do |parameter:, type_argument:, default:, origin:|
      Rip::Parser::Node.new(
        type: :optional_parameter,
        name: parameter.to_s,
        type_argument: type_argument,
        default: default,
        location: Rip::Parser::Location.from_slice(origin, parameter)
      )
    end


    rule(fat_rocket: simple(:location), overloads: sequence(:overloads)) do |location:, overloads:, origin:|
      Rip::Parser::Node.new(
        type: :lambda,
        overloads: overloads,
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end


    rule(swerve_rocket: simple(:location), body: simple(:expression)) do |location:, expression:, origin:|
      Rip::Parser::Node.new(
        type: :property,
        body: [ expression ],
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end

    rule(swerve_rocket: simple(:location), body: sequence(:expressions)) do |location:, expressions:, origin:|
      Rip::Parser::Node.new(
        type: :property,
        body: expressions,
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end


    rule(property_name: simple(:name)) do |name:, origin:|
      Rip::Parser::Node.new(
        type: :class_property,
        name: name.to_s,
        location: Rip::Parser::Location.from_slice(origin, name)
      )
    end

    rule(class_self: simple(:self), location: simple(:location), property_name: simple(:name)) do |self:, location:, name:, origin:|
      Rip::Parser::Node.new(
        type: :class_property,
        name: name.to_s,
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end

    rule(class_prototype: simple(:prototype), location: simple(:location), property_name: simple(:name)) do |prototype:, location:, name:, origin:|
      Rip::Parser::Node.new(
        type: :prototype_property,
        name: name.to_s,
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end


    rule(property: simple(:property), location: simple(:location), property_value: simple(:value)) do |property:, location:, value:, origin:|
      property.merge(value: value)
    end


    rule(class: simple(:location), body: simple(:class_property)) do |location:, class_property:, origin:|
      Rip::Parser::Node.new(
        type: :class,
        properties: Array(class_property),
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end

    rule(class: simple(:location), body: sequence(:class_properties)) do |location:, class_properties:, origin:|
      Rip::Parser::Node.new(
        type: :class,
        properties: class_properties,
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end


    rule(if: simple(:location), condition: simple(:condition), consequence: simple(:consequence), else: 'else', alternative: simple(:alternative)) do |location:, condition:, consequence:, alternative:, origin:|
      Rip::Parser::Node.new(
        type: :binary_condition,
        condition: condition,
        consequence: [ consequence ],
        alternative: [ alternative ],
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end

    rule(if: simple(:location), condition: simple(:condition), consequence: simple(:consequence), else: 'else', alternative: sequence(:alternative)) do |location:, condition:, consequence:, alternative:, origin:|
      Rip::Parser::Node.new(
        type: :binary_condition,
        condition: condition,
        consequence: [ consequence ],
        alternative: alternative,
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end

    rule(if: simple(:location), condition: simple(:condition), consequence: sequence(:consequence), else: 'else', alternative: simple(:alternative)) do |location:, condition:, consequence:, alternative:, origin:|
      Rip::Parser::Node.new(
        type: :binary_condition,
        condition: condition,
        consequence: consequence,
        alternative: [ alternative ],
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end

    rule(if: simple(:location), condition: simple(:condition), consequence: sequence(:consequence), else: 'else', alternative: sequence(:alternative)) do |location:, condition:, consequence:, alternative:, origin:|
      Rip::Parser::Node.new(
        type: :binary_condition,
        condition: condition,
        consequence: consequence,
        alternative: alternative,
        location: Rip::Parser::Location.from_slice(origin, location)
      )
    end
  end
end
