require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Assignment do
  class AssignmentParser
    include Rip::Parser::Rules::Assignment
    include Rip::Parser::Rules::Module
  end

  let(:parser) { AssignmentParser.new }

  describe '#reference_assignment' do
    subject { parser.reference_assignment }

    it { should_not parse('a.b = 42') }

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

  describe '#property_assignment' do
    subject { parser.property_assignment }

    it { should_not parse('a = 42') }

    it do
      should parse('a.b = 42').as(
        lhs: {
          object: { reference: 'a' },
          location: '.',
          property_name: 'b'
        },
        location: '=',
        rhs: {
          expression_chain: { integer: '42' }
        }
      )
    end
  end
end
