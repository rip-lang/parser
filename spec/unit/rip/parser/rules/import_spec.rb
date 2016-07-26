require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Import do
  class ImportParser
    include Rip::Parser::Rules::Import
  end

  let(:parser) { ImportParser.new }

  describe '#import' do
    subject { parser.import }

    it do
      should parse('import :foo').as(import: 'import', module_name: {
        location: ':',
        string: [
          { character: 'f' },
          { character: 'o' },
          { character: 'o' }
        ]
      })
    end

    it do
      should parse('import(:bar)').as(import: 'import', module_name: {
        location: ':',
        string: [
          { character: 'b' },
          { character: 'a' },
          { character: 'r' }
        ]
      })
    end

    it do
      should parse('import "bar"').as(import: 'import', module_name: {
        location: '"',
        string: [
          { character: 'b' },
          { character: 'a' },
          { character: 'r' }
        ]
      })
    end

    it do
      should parse('import "./a/b"').as(import: 'import', module_name: {
        location: '"',
        string: [
          { character: '.' },
          { character: '/' },
          { character: 'a' },
          { character: '/' },
          { character: 'b' }
        ]
      })
    end
  end
end
