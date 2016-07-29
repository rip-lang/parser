require 'spec_helper'

RSpec.describe Rip::Parser::Rules::InvocationIndex do
  class InvocationIndexParser
    include ::Parslet

    include Rip::Parser::Rules::Expression
    include Rip::Parser::Rules::InvocationIndex
  end

  let(:parser) { InvocationIndexParser.new }

  describe '#invocation_index' do
    subject { parser.invocation_index }

    it { should parse('[]').as(location: '[', index_arguments: []) }

    it do
      should parse('[`3]').as(
        location: '[',
        index_arguments: [
          {
            expression_chain: { character: '3', location: '`' }
          }
        ]
      )
    end

    it do
      should parse('[1, 2, 3]').as(
        location: '[',
        index_arguments: [
          {
            expression_chain: { integer: '1' }
          },
          {
            expression_chain: { integer: '2' }
          },
          {
            expression_chain: { integer: '3' }
          }
        ]
      )
    end
  end
end
