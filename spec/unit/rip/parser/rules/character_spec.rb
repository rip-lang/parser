require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Character do
  class CharacterParser
    include Rip::Parser::Rules::Character
  end

  let(:parser) { CharacterParser.new }

  describe '#character' do
    subject { parser.character }

    it { should parse('`c').as(location: '`', character: 'c') }
    it { should parse('`\n').as(location: '`', escape_location: '\\', escape_special: 'n') }
  end

  describe '#escape_sequence' do
    subject { parser.escape_sequence }

    it { should parse('\u1234').as(escape_location: '\\', escape_unicode: '1234') }

    described_class::SPECIAL_ESCAPES.each do |_, sequence|
      it { should parse("\\#{sequence}").as(escape_location: '\\', escape_special: sequence) }
    end

    it { should parse('\w').as(escape_location: '\\', escape_any: 'w') }
    it { should_not parse('\ ') }
  end
end
