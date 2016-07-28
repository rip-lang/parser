require 'spec_helper'

RSpec.describe Rip::Parser do
  let(:fixtures) { Rip::Parser.root + 'spec' + 'fixtures' }

  describe '.load' do
  end

  describe '.load_file' do
    let(:parse_tree) { Rip::Parser.load_file(fixtures + 'syntax_sample.rip') }
    subject { parse_tree }

    it { should be_an_instance_of(Hashie::Mash) }

    context 'top-level' do
      let(:actual_counts) do
        parse_tree.module.map(&:keys).map do |keys|
          keys.map(&:to_sym).reject do |key|
            key == :location
          end.sort
        end.sort.group_by do |keys|
          keys
        end.map do |keys, all_keys|
          [ keys, all_keys.count ]
        end.to_h
      end

      let(:expected_counts) do
        {
          [ :arguments, :callable ] => 2,
          [ :key, :value ]          => 2,
          [ :lhs, :rhs ]            => 4,
          [ :list ]                 => 1,
          [ :module_name ]          => 2,
          [ :regular_expression ]   => 1,
          [ :string ]               => 1
        }
      end

      specify { expect(expected_counts).to eq(actual_counts) }
    end

    context 'spot-checks' do
      let(:list) { parse_tree.module.select(&:list).first.list }

      let(:range) do
        parse_tree.module.select(&:value).detect do |pair|
          pair[:key].string.map(&:character).join('') == 'range'
        end.value
      end

      specify { expect(list.count).to eq(3) }

      specify { expect(list.select(&:character).count).to eq(1) }

      specify { expect(list.select(&:escape_special).count).to eq(1) }

      specify { expect(list.select(&:escape_unicode).count).to eq(1) }

      specify { expect(range.start.integer).to eq('0') }
      specify { expect(range.end.object.integer).to eq('9') }
    end

    context 'pathelogical nesting' do
      let(:property_chain) do
        parse_tree.module.select(&:lhs).detect do |assignment|
          assignment.lhs.reference == 'please-dont-ever-do-this'
        end.rhs
      end

      specify { expect(property_chain.object.callable.object.reference).to eq('foo') }
      specify { expect(property_chain.object.callable.property_name).to eq('bar') }

      specify { expect(property_chain.object.arguments).to eq([]) }
      specify { expect(property_chain.property_name).to eq('baz') }
    end
  end

  describe '.root' do
    specify { expect(Rip::Parser.root).to eq(Pathname.new(__dir__).parent.parent.parent.expand_path) }
  end
end
