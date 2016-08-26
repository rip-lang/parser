require 'spec_helper'

RSpec.describe Rip::Parser do
  let(:fixtures) { Rip::Parser.root + 'spec' + 'fixtures' }

  describe '.load' do
  end

  describe '.load_file' do
    let(:parse_tree) { Rip::Parser.load_file(fixtures + 'syntax_sample.rip') }
    subject { parse_tree }

    def find_rhs(name)
      parse_tree.expressions.select(&:assignment?).detect do |assignment|
        assignment.lhs.name == name.to_s
      end.rhs
    end

    it { should be_an_instance_of(Rip::Parser::Node) }

    context 'top-level' do
      let(:expressions) { parse_tree.expressions }

      let(:assignment_values) do
        parse_tree.expressions.select(&:assignment?).map(&:rhs)
      end

      let(:actual_counts) do
        [
          *expressions,
          *assignment_values
        ].sort_by(&:type).group_by(&:type).map do |type, expression|
          [ type, expression.count ]
        end.to_h
      end

      let(:expected_counts) do
        {
          assignment:         16,
          class:               2,
          date_time:           1,
          import:              2,
          integer:             1,
          invocation:          5,
          invocation_index:    1,
          lambda:              2,
          list:                3,
          map:                 1,
          overload:            3,
          pair:                1,
          property_access:     2,
          regular_expression:  2,
          string:              2,
          unit:                2
        }
      end

      specify { expect(actual_counts).to eq(expected_counts) }
    end

    context 'spot-checks' do
      let(:list) { parse_tree.expressions.detect { |e| e.type == :list } }

      let(:range) do
        parse_tree.expressions.select(&:pair?).detect do |pair|
          pair[:key].characters.map(&:data).join('') == 'range'
        end.value
      end

      let(:lunch_time) { find_rhs('lunch-time') }

      specify { expect(list.items.count).to eq(3) }

      specify { expect(list.items.select(&:character?).count).to eq(1) }

      specify { expect(list.items.select(&:escape_special?).count).to eq(1) }

      specify { expect(list.items.select(&:escape_unicode?).count).to eq(1) }

      specify { expect(range.start.integer).to eq('0') }
      specify { expect(range.end.object.integer).to eq('9') }

      specify { expect(find_rhs(:map).pairs.count).to eq(1) }

      specify do
        expect(lunch_time.type).to eq(:invocation)
        expect(lunch_time.callable.type).to eq(:property_access)
        expect(lunch_time.callable.object.type).to eq(:time)
      end
    end

    context 'pathelogical nesting' do
      let(:property_chain) { find_rhs('please-dont-ever-do-this') }

      specify { expect(property_chain.object.callable.object.name).to eq('foo') }
      specify { expect(property_chain.object.callable.property_name).to eq('bar') }

      specify { expect(property_chain.object.arguments).to eq([]) }
      specify { expect(property_chain.property_name).to eq('baz') }
    end
  end

  describe '.root' do
    specify { expect(Rip::Parser.root).to eq(Pathname.new(__dir__).parent.parent.parent.expand_path) }
  end
end
