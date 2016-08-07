require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Assignment do
  class AssignmentParser
    include Rip::Parser::Rules::Assignment
  end

  let(:parser) { AssignmentParser.new }

  describe '#assignment' do
    subject { parser.assignment }

    it do
      should parse('answer = 42').as(
        lhs: { reference: 'answer' },
        location: '=',
        rhs: {
          expression_chain: { integer: '42' }
        }
      )
    end

    it do
      should parse('answer = foo.bar').as(
        lhs: { reference: 'answer' },
        location: '=',
        rhs: {
          expression_chain: [
            { reference: 'foo' },
            { location: '.', property_name: 'bar' }
          ]
        }
      )
    end
  end
end
