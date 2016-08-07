require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Map do
  class MapParser
    include Parslet

    include Rip::Parser::Rules::Map
    include Rip::Parser::Rules::Reference
    include Rip::Parser::Rules::String

    rule(:expression) { reference | string | map }
  end

  let(:parser) { MapParser.new }

  describe '#map' do
    subject { parser.map }

    it { should parse('{}').as(location: '{', map: []) }

    it do
      should parse('{ a, b, c }').as(location: '{', map: [
        { reference: 'a' },
        { reference: 'b' },
        { reference: 'c' }
      ])
    end

    it do
      should parse('{ nested, {} }').as(location: '{', map: [
        { reference: 'nested' },
        { location: '{', map: [] }
      ])
    end
  end
end
