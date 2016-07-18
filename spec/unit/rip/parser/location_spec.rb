require 'spec_helper'

RSpec.describe Rip::Parser::Location do
  subject { location }
  let(:location) { Rip::Parser::Location.new(:rspec, 0, 1, 0) }

  describe '#==' do
    it 'glosses over superficial differences' do
      expect(location).to eq(Rip::Parser::Location.new(:rspec, 0, 1, 0))
    end

    it 'notices important difference in source' do
      expect(location).not_to eq(location_for(:origin => :cucumber))
    end

    it 'notices important differences in position' do
      expect(location).not_to eq(location_for(:offset => 3))
    end
  end

  describe '#to_s' do
    specify { expect(subject.to_s).to eq('rspec:1:0(0)') }

    context 'in another file' do
      let(:location) { Rip::Parser::Location.new('lib/rip.rip', 47, 8, 3, 5) }

      specify { expect(subject.to_s).to eq('lib/rip.rip:8:3(47..51)') }
    end
  end

  describe '#add_character' do
    let(:new_location) { Rip::Parser::Location.new(:rspec, 5, 1, 5) }

    it 'returns a new location offset by specified characters' do
      expect(location.add_character(5)).to eq(new_location)
    end
  end

  describe '#add_line' do
    let(:new_location) { Rip::Parser::Location.new(:rspec, 2, 3, 2) }

    it 'returns a new location offset by specified lines' do
      expect(location.add_line(2)).to eq(new_location)
    end
  end

  describe '.from_slice' do
    let(:location) { Rip::Parser::Location.from_slice(:rspec, slice) }

    let(:parser) do
      Class.new(Parslet::Parser) do
        root :lines

        rule(:lines) { line.repeat }
        rule(:line) { (as | bs).as(:line) >> eol }

        rule(:as) { a.repeat(3) }
        rule(:bs) { b.repeat(3) }

        rule(:a) { str('a').as(:a) }
        rule(:b) { str('b').as(:b) }

        rule(:eol) { str("\n") }
      end.new
    end

    let(:slice) { slices[4] }
    let(:slices) { tree.map(&:values).flatten.map(&:values).flatten }

    let(:source) do
      strip_heredoc(<<-SOURCE)
        aaa
        bbb
      SOURCE
    end

    let(:tree) { parser.parse(source) }

    specify { expect(location.origin).to eq(:rspec) }

    specify { expect(location.offset).to eq(5) }

    specify { expect(location.line).to eq(2) }

    specify { expect(location.column).to eq(2) }

    specify { expect(location.length).to eq(1) }
  end
end
