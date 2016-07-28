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
      let(:expressions) { parse_tree.module }

      specify { expect(expressions.count).to eq(13) }

      specify { expect(expressions.select(&:module_name).count).to eq(2) }

      specify { expect(expressions.select(&:list).count).to eq(1) }

      specify { expect(expressions.select(&:lhs).count).to eq(4) }

      specify { expect(expressions.select(&:string).count).to eq(1) }

      specify { expect(expressions.select(&:regular_expression).count).to eq(1) }

      specify { expect(expressions.select(&:value).count).to eq(2) }

      specify { expect(expressions.select(&:callable).count).to eq(2) }
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
