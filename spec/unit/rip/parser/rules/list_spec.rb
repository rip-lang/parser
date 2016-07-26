require 'spec_helper'

RSpec.describe Rip::Parser::Rules::List do
  class ListParser
    include Parslet

    include Rip::Parser::Rules::List
    include Rip::Parser::Rules::Number
    include Rip::Parser::Rules::String

    rule(:expression) { number | string | list }
  end

  let(:parser) { ListParser.new }

  describe '#list' do
    subject { parser.list }

    it { should parse('[]').as(location: '[', list: []) }

    it do
      should parse('[ 1, 2, 3.14 ]').as(location: '[', list: [
        { integer: '1' },
        { integer: '2' },
        { integer: '3', decimal: '14' }
      ])
    end

    it do
      should parse('[ "nested", [] ]').as(location: '[', list: [
        {
          location: '"', string: [
            { character: 'n' },
            { character: 'e' },
            { character: 's' },
            { character: 't' },
            { character: 'e' },
            { character: 'd' }
          ]
        },
        { location: '[', list: [] }
      ])
    end
  end
end
