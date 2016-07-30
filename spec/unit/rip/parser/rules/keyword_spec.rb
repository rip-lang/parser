require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Keyword do
  class KeywordParser
    include Rip::Parser::Rules::Keyword
  end

  let(:parser) { KeywordParser.new }

  describe '#keyword' do
    subject { parser.keyword(:import) }

    it { should parse('import').as(import: 'import') }

    it { should_not parse('importer') }
  end
end
