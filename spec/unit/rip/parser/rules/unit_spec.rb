require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Unit do
  class UnitParser
    include Rip::Parser::Rules::Unit
  end

  let(:parser) { UnitParser.new }

  describe '#unit' do
    subject { parser.unit }

    it { should parse('-42°').as(magnitude: { sign: '-', integer: '42' }, label: '°') }

    it { should parse('6.28circle').as(magnitude: { integer: '6', decimal: '28' }, label: 'circle') }
  end
end
