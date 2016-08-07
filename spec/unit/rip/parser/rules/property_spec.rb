require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Property do
  class PropertyParser
    include Rip::Parser::Rules::Property
  end

  let(:parser) { PropertyParser.new }

  describe '#property' do
    subject { parser.property }

    it { should parse('.code').as(location: '.', property_name: 'code') }
    it { should parse("\n.code").as(location: '.', property_name: 'code') }
    it { should parse(".\ncode").as(location: '.', property_name: 'code') }
  end

  describe '#property_name' do
    subject { parser.property_name }

    Rip::Parser::Rules::Property::SPECIAL_NAMES.each do |name|
      it { should parse(name) }
    end

    it { should_not parse('>~<') }
  end
end
