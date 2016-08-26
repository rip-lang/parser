require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Range do
  class RangeParser
    include ::Parslet

    include Rip::Parser::Rules::Module
    include Rip::Parser::Rules::Range
  end

  let(:parser) { RangeParser.new }

  describe '#range_end' do
    subject { parser.range_end }

    it do
      should parse('..`z').as(
        location: '..',
        end: {
          expression_chain: { character: 'z', location: '`' }
        }
      )
    end

    it do
      should parse('..5.to_float').as(
        location: '..',
        end: {
          expression_chain: [
            { integer: '5' },
            { property_name: 'to_float', location: '.' }
          ]
        }
      )
    end
  end
end
