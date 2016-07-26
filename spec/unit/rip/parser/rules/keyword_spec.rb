require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Keyword do
  class KeywordParser
    include Rip::Parser::Rules::Keyword
  end

  let(:parser) { KeywordParser.new }

  describe '#keyword' do
    subject { parser.keyword(:foo) }

    it { should parse('foo').as(foo: 'foo') }

    it { should_not parse('fool') }
  end
end
