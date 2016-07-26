require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Common do
  class CommonParser
    include Rip::Parser::Rules::Common
  end

  let(:parser) { CommonParser.new }

  describe '#comment' do
    subject { parser.comment }

    it { should parse('#') }
    it { should parse('# comment') }
  end

  describe '#space' do
    subject { parser.space }

    it { should parse(' ') }
    it { should parse("\t") }
  end

  describe '#spaces' do
    subject { parser.spaces }

    it { should parse(' ') }
    it { should parse("\t\t") }
    it { should parse("  \t  \t  ") }
  end

  describe '#spaces?' do
    subject { parser.spaces? }

    it { should parse('') }
    it { should parse(' ') }
    it { should parse("  \t  \t  ") }
  end

  describe '#line_break' do
    subject { parser.line_break }

    it { should parse("\n") }
    it { should parse("\r") }
    it { should parse("\r\n") }
  end

  describe '#line_breaks' do
    subject { parser.line_breaks }

    it { should parse("\r\n\r\n") }
    it { should parse("\n\n") }
    it { should parse("\r\r") }
  end

  describe '#line_breaks?' do
    subject { parser.line_breaks? }

    it { should parse('') }
    it { should parse("\r\n\r\n") }
    it { should parse("\n\n") }
  end

  describe '#whitespace' do
    subject { parser.whitespace }

    it { should parse(' ') }
    it { should parse("\t") }
    it { should parse("\n") }
    it { should parse("\r") }
    it { should parse("\r\n") }
  end

  describe '#whitespaces' do
    subject { parser.whitespaces }

    it { should parse(' ') }
    it { should parse("\t\t") }
  end

  describe '#whitespaces?' do
    subject { parser.whitespaces? }

    it { should parse('') }
    it { should parse("\n") }
    it { should parse("\t\r") }
  end
end
