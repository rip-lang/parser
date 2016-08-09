require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Pair do
  class PairParser
    include ::Parslet

    include Rip::Parser::Rules::Module
    include Rip::Parser::Rules::Pair
  end

  let(:parser) { PairParser.new }

  describe '#pair_value' do
    subject { parser.pair_value }

    it do
      should parse(': value').as(
        location: ':',
        value: {
          expression_chain: { reference: 'value' }
        }
      )
    end
  end
end
