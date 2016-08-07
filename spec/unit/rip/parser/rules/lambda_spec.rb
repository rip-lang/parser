require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Lambda do
  class LambdaParser
    include Rip::Parser::Rules::Lambda
    include Rip::Parser::Rules::Module
  end

  let(:parser) { LambdaParser.new }

  describe '#lambda_block' do
    subject { parser.lambda_block }

    it do
      should parse('=> { -> { 42 } }').as(
        fat_rocket: '=>',
        overloads: [
          {
            dash_rocket: '->',
            body: { expression_chain: { integer: '42' } }
          }
        ]
      )
    end

    it do
      should parse('=> { -> { 42 } (foo) -> { foo } }').as(
        fat_rocket: '=>',
        overloads: [
          {
            dash_rocket: '->',
            body: { expression_chain: { integer: '42' } }
          },
          {
            dash_rocket: '->',
            parameters: [ { parameter: 'foo' } ],
            body: { expression_chain: { reference: 'foo' } }
          }
        ]
      )
    end

    it { should_not parse('=> { }') }
  end

  describe '#overload_block' do
    subject { parser.overload_block }

    it do
      should parse('-> { 42 }').as(
        dash_rocket: '->',
        body: { expression_chain: { integer: '42' } }
      )
    end

    it do
      should parse('() -> { 42 }').as(
        dash_rocket: '->',
        parameters: [],
        body: { expression_chain: { integer: '42' } }
      )
    end

    it { should_not parse('-> {}') }
  end

  describe '#parameters' do
    subject { parser.parameters }

    it { should parse('()').as(parameters: []) }

    it do
      should parse('(foo)').as(
        parameters: [
          { parameter: 'foo' }
        ]
      )
    end

    it do
      should parse('(foo<integer>, bar)').as(
       parameters: [
          { parameter: 'foo', type_argument: { reference: 'integer' } },
          { parameter: 'bar' }
        ]
      )
    end

    it do
      should parse('(foo<integer> = 42)').as(
       parameters: [
          { parameter: 'foo', default: { expression_chain: { integer: '42' } }, type_argument: { reference: 'integer' } }
        ]
      )
    end

    it do
      should parse('(foo, bar<integer>, baz = 42)').as(
        parameters: [
          { parameter: 'foo' },
          { parameter: 'bar', type_argument: { reference: 'integer' } },
          { parameter: 'baz', default: { expression_chain: { integer: '42' } } }
        ]
      )
    end
  end

  describe '#required_parameter' do
    subject { parser.required_parameter }

    it { should parse('foo').as(parameter: 'foo') }

    it do
      should parse('foo<bar>').as(
        parameter: 'foo',
        type_argument: { reference: 'bar' }
      )
    end
  end

  describe '#optional_parameter' do
    subject { parser.optional_parameter }

    it do
      should parse('foo = 42').as(
        parameter: 'foo',
        default: { expression_chain: { integer: '42' } }
      )
    end

    it do
      should parse('foo<bar> = 42').as(
        parameter: 'foo',
        default: { expression_chain: { integer: '42' } },
        type_argument: { reference: 'bar' }
      )
    end
  end

  describe '#parameter_type_argument' do
    subject { parser.parameter_type_argument }

    it { should parse('<foo>').as(type_argument: { reference: 'foo' }) }
  end

  describe '#block_body' do
    subject { parser.block_body }

    it do
      should parse('{ :one }').as(
        body: { expression_chain: { location: ':', string: [
          { character: 'o' },
          { character: 'n' },
          { character: 'e' }
        ] } }
      )
    end

    it do
      should parse('{ 42; :cat }').as(
        body: [
          { expression_chain: { integer: '42' } },
          { expression_chain: { location: ':', string: [
            { character: 'c' },
            { character: 'a' },
            { character: 't' }
          ] } }
        ]
      )
    end

    it { should_not parse('{}') }
  end
end
