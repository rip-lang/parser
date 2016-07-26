require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Module do
  class ModuleParser
    include Parslet

    include Rip::Parser::Rules::Module
    include Rip::Parser::Rules::Number
    include Rip::Parser::Rules::String

    rule(:expression) { number | string | list }
  end

  let(:parser) { ModuleParser.new }

  describe '#module' do
    subject { parser.module }

    it do
      should parse('42;3.14').as(module: [
        { integer: '42' },
        { integer: '3', decimal: '14' }
      ])
    end

    it do
      should parse(":foo\n:bar\n:baz").as(module: [
        {
          location: ':',
          string: [
            { character: 'f' },
            { character: 'o' },
            { character: 'o' }
          ]
        },
        {
          location: ':',
          string: [
            { character: 'b' },
            { character: 'a' },
            { character: 'r' }
          ]
        },
        {
          location: ':',
          string: [
            { character: 'b' },
            { character: 'a' },
            { character: 'z' }
          ]
        }
      ])
    end

    it { should_not parse('') }

    it { should_not parse('# comment') }

    it { should_not parse('42 3.14') }

    it { should_not parse(':aaa :bbb') }
  end
end
