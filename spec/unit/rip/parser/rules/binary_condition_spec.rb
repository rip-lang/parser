require 'spec_helper'

RSpec.describe Rip::Parser::Rules::BinaryCondition do
  class BinaryConditionParser
    include Rip::Parser::Rules::BinaryCondition
    include Rip::Parser::Rules::Module
  end

  let(:parser) { BinaryConditionParser.new }

  describe '#binary_condition' do
    subject { parser.binary_condition }

    it do
      should parse('if (result) { :yes } else { :no }').as(
        if: 'if',
        condition: { expression_chain: { reference: 'result' } },
        consequence: {
          expression_chain: {
            location: ':',
            string: [
              { character: 'y' },
              { character: 'e' },
              { character: 's' }
            ]
          }
        },
        else: 'else',
        alternative: {
          expression_chain: {
            location: ':',
            string: [
              { character: 'n' },
              { character: 'o' }
            ]
          }
        }
      )
    end
  end
end
