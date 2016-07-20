require 'spec_helper'

RSpec.describe Rip::Parser::Rules::String do
  class StringParser
    include Rip::Parser::Rules::String
  end

  let(:parser) { StringParser.new }

  describe '#string' do
    subject { parser.string }

    it { should parse(':rip') }
    it { should parse('""') }
    it { should parse('"foo-bar-baz"') }
  end

  describe '#string_symbol' do
    subject { parser.string_symbol }

    it do
      should parse(':cat').as(location: ':', string: [
        { character: 'c' },
        { character: 'a' },
        { character: 't' }
      ])
    end

    it do
      should parse(':7').as(location: ':', string: [
        { character: '7' }
      ])
    end
  end

  describe '#string_double' do
    subject { parser.string_double }

    it do
      should parse('"dog"').as(location: '"', string: [
        { character: 'd' },
        { character: 'o' },
        { character: 'g' }
      ])
    end

    it do
      should parse('"a\nb"').as(location: '"', string: [
        { character: 'a' },
        { character: { escape_special: 'n' } },
        { character: 'b' }
      ])
    end
  end

  describe '#regular_expression' do
    subject { parser.regular_expression }

    it do
      should parse('/r\.p/').as(location: '/', regular_expression: [
        { character: 'r' },
        { character: { escape_any: '.' } },
        { character: 'p' }
      ])
    end
  end

  describe '#heredoc' do
    subject { parser.heredoc }

    let(:rip) do
      strip_heredoc(<<-RIP)
        <<BLOCK
        multi-line
        string
        BLOCK
      RIP
    end

    it do
      should parse(rip).as(location: '<<', string: [
        { character: 'm' }, { character: 'u' }, { character: 'l' }, { character: 't' },
        { character: 'i' }, { character: '-' }, { character: 'l' }, { character: 'i' },
        { character: 'n' }, { character: 'e' }, { character: "\n" }, { character: 's' },
        { character: 't' }, { character: 'r' }, { character: 'i' }, { character: 'n' },
        { character: 'g' }, { character: "\n" }
      ])
    end
  end
end
