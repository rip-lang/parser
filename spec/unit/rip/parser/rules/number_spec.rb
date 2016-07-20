require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Number do
  class NumberParser
    include Rip::Parser::Rules::Number
  end

  let(:parser) { NumberParser.new }

  describe '#integer' do
    subject { parser.integer }

    it { should parse('42').as(integer: '42') }
  end

  describe '#decimal' do
    subject { parser.decimal }

    it { should parse('3.14').as(integer: '3', decimal: '14') }
  end

  describe '#number' do
    subject { parser.number }

    it { should parse('42').as(integer: '42') }
    it { should parse('+42').as(integer: '42', sign: '+') }
    it { should parse('-3.14').as(integer: '3', decimal: '14', sign: '-') }
  end

  describe '#digits' do
    subject { parser.digits }

    it { should parse('0') }
    it { should parse('1_234_567_890') }

    it { should_not parse('_1') }
    it { should_not parse('2_') }
    it { should_not parse('3__4') }
  end
end
