require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Invocation do
  class InvocationParser
    include ::Parslet

    include Rip::Parser::Rules::Expression
    include Rip::Parser::Rules::Invocation
  end

  let(:parser) { InvocationParser.new }

  describe '#invocation' do
    subject { parser.invocation }

    it { should parse('()').as(location: '(', arguments: []) }

    it do
      should parse('(`3)').as(
        location: '(',
        arguments: [
          {
            expression_chain: { character: '3', location: '`' }
          }
        ]
      )
    end

    it do
      should parse('(1, 2, 3)').as(
        location: '(',
        arguments: [
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
