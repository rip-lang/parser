require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Expression do
  class ExpressionParser
    include Rip::Parser::Rules::Expression
  end

  let(:parser) { ExpressionParser.new }

  describe '#expression' do
    subject { parser.expression }

    it { should parse('42') }
    it { should parse('-39.7') }

    it { should parse('`r') }

    it { should parse(':rip') }

    it { should parse('[ "nested", [] ]') }

    it { should parse('foo') }

    it { should parse('import :bar') }

    context 'with nested parenthesis' do
      it { should parse('(( ((`z))) )') }
      it { should parse('(import :bar)') }
    end

    context 'chaining' do
      it do
        should parse('foo.bar').as(expression_chain: [
          { reference: 'foo' },
          { location: '.', property_name: 'bar' }
        ])
      end

      it do
        should parse('a.b.c').as(expression_chain: [
          { reference: 'a' },
          { location: '.', property_name: 'b' },
          { location: '.', property_name: 'c' }
        ])
      end

      it do
        should parse('(((((foo).bar()).baz)))').as(expression_chain: {
            expression_chain: {
              expression_chain: {
                expression_chain: [
                  {
                    expression_chain: [
                      {
                        expression_chain: { reference: 'foo' }
                      },
                      { location: '.', property_name: 'bar' },
                      { location: '(', arguments: [] }
                    ]
                  },
                  { location: '.', property_name: 'baz' }
                ]
              }
            }
          }
        )
      end
    end
  end
end
