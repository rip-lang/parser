require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Class do
  class ClassParser
    include Rip::Parser::Rules::Class
    include Rip::Parser::Rules::Module
  end

  let(:parser) { ClassParser.new }

  describe '#class_block' do
    subject { parser.class_block }

    it do
      should parse('class {}').as(
        class: 'class',
        body: nil
      )
    end

    it do
      should parse('class (Collection) { self.foo = 42 }').as(
        class: 'class',
        ancestors: [
          { reference: 'Collection' }
        ],
        body: {
          class_self: 'self',
          property_name: 'foo',
          location: '=',
          property_value: { expression_chain: { integer: '42' } }
        }
      )
    end

    it do
      should parse('class () { foo = 42; @.bar = ~> { `F } }').as(
        class: 'class',
        ancestors: [],
        body: [
          {
            property_name: 'foo',
            location: '=',
            property_value: { expression_chain: { integer: '42' } }
          },
          {
            class_prototype: '@',
            property_name: 'bar',
            location: '=',
            property_value: {
              swerve_rocket: '~>',
              body: { expression_chain: { location: '`', character: 'F' } }
            }
          }
        ]
      )
    end
  end

  describe '#class_ancestors' do
    subject { parser.class_ancestors }

    it { should parse('()').as(ancestors: []) }

    it do
      should parse('(Queryable)').as(
        ancestors: [
          { reference: 'Queryable' }
        ]
      )
    end

    it do
      should parse('(Collection, Queryable)').as(
        ancestors: [
          { reference: 'Collection' },
          { reference: 'Queryable' }
        ]
      )
    end
  end

  describe '#property_assignment' do
    subject { parser.property_assignment }

    it do
      should parse('foo = 42').as(
        {
          property_name: 'foo',
          location: '=',
          property_value: { expression_chain: { integer: '42' } }
        }
      )
    end

    it do
      should parse('foo = ~> { 42 }').as(
        {
          property_name: 'foo',
          location: '=',
          property_value: {
            swerve_rocket: '~>',
            body: { expression_chain: { integer: '42' } }
          }
        }
      )
    end

    it do
      should parse('self.[] = -> { 42 }').as(
        {
          class_self: 'self',
          property_name: '[]',
          location: '=',
          property_value: {
            dash_rocket: '->',
            body: { expression_chain: { integer: '42' } }
          }
        }
      )
    end

    it do
      should parse('@.[] = => { -> { 42 } }').as(
        {
          class_prototype: '@',
          property_name: '[]',
          location: '=',
          property_value: {
            fat_rocket: '=>',
            overloads: [
              {
                dash_rocket: '->',
                body: { expression_chain: { integer: '42' } }
              }
            ]
          }
        }
      )
    end
  end

  describe '#property_block' do
    subject { parser.property_block }

    it do
      should parse('~> { 42 }').as(
        swerve_rocket: '~>',
        body: { expression_chain: { integer: '42' } }
      )
    end

    it { should_not parse('~> {}') }
  end
end
