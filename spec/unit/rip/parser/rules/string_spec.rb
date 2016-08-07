require 'spec_helper'

RSpec.describe Rip::Parser::Rules::String do
  class StringParser
    include ::Parslet

    include Rip::Parser::Rules::Reference
    include Rip::Parser::Rules::String

    rule(:expression) { reference }
  end

  let(:parser) { StringParser.new }

  describe '#string' do
    subject { parser.string }

    it { should parse(':rip') }
    it { should parse('""') }
    it { should parse('"foo-bar-baz"') }

    it do
      should parse(strip_heredoc(<<-RIP))
        <<DOC
          foo
          bar
          baz
        DOC
      RIP
    end
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

    it { should_not parse(':foo#{bar}baz') }
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
        { escape_location: '\\', escape_special: 'n' },
        { character: 'b' }
      ])
    end

    it do
      should parse('"foo#{bar}baz"').as(location: '"', string: [
        { character: 'f' },
        { character: 'o' },
        { character: 'o' },
        { location: '#{', interpolation: { reference: 'bar' } },
        { character: 'b' },
        { character: 'a' },
        { character: 'z' }
      ])
    end
  end

  describe '#regular_expression' do
    subject { parser.regular_expression }

    it do
      should parse('/r\.p/').as(location: '/', regular_expression: [
        { character: 'r' },
        { escape_location: '\\', escape_any: '.' },
        { character: 'p' }
      ])
    end

    it do
      should parse('/f#{bar}b/').as(location: '/', regular_expression: [
        { character: 'f' },
        { location: '#{', interpolation: { reference: 'bar' } },
        { character: 'b' }
      ])
    end
  end

  describe '#heredoc' do
    subject { parser.heredoc }

    context 'normal' do
      let(:rip) do
        strip_heredoc(<<-RIP)
          <<BLOCK
          multi-line
          string
          BLOCK
        RIP
      end

      it do
        should parse(rip).as(location: '<<', label: 'BLOCK', string: [
          { character: 'm' }, { character: 'u' }, { character: 'l' }, { character: 't' },
          { character: 'i' }, { character: '-' }, { character: 'l' }, { character: 'i' },
          { character: 'n' }, { character: 'e' }, { character: "\n" }, { character: 's' },
          { character: 't' }, { character: 'r' }, { character: 'i' }, { character: 'n' },
          { character: 'g' }, { character: "\n" }
        ])
      end
    end

    context 'interpolation' do
      let(:rip) do
        strip_heredoc(<<-RIP)
          <<BLOCK
          \#{answer}
          BLOCK
        RIP
      end

      it do
        should parse(rip).as(location: '<<', label: 'BLOCK', string: [
          { location: '#{', interpolation: { reference: 'answer' } },
          { character: "\n" }
        ])
      end
    end

    context 'pathelogical' do
      let(:rip) do
        strip_heredoc(<<-RIP)
          <<BLOCK

          \\tfoo

          BLOCK
        RIP
      end

      it do
        should parse(rip).as(location: '<<', label: 'BLOCK', string: [
          { character: "\n" },
          { escape_location: '\\', escape_special: 't' }, { character: 'f' }, { character: 'o' }, { character: 'o' }, { character: "\n" },
          { character: "\n" }
        ])
      end
    end
  end
end
