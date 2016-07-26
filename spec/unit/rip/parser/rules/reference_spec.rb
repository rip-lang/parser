require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Reference do
  class ReferenceParser
    include Rip::Parser::Rules::Reference
  end

  let(:parser) { ReferenceParser.new }

  describe '#reference' do
    subject { parser.reference }

    [
      'name',
      'Person',
      '==',
      'save!',
      'valid?',
      'long_ref-name',
      '*-+&$~%',
      'one_9',
      'É¹ÇÊ‡É¹oÔ€uÉlâˆ€â„¢',
      'nilly',
      'nil',
      'true',
      'false',
      'System',
      'returner'
    ].each do |word|
      it { should parse(word).as(reference: word) }
    end

    [
      'one.two',
      '999',
      '6teen',
      'rip rocks',
      'key:value'
    ].each do |word|
      it { should_not parse(word) }
    end
  end
end
