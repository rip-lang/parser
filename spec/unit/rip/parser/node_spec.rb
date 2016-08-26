require 'spec_helper'

RSpec.describe Rip::Parser::Node do
  let(:location) { Rip::Parser::Location.new(:rspec, 0, 1, 0) }
  let(:node) { Rip::Parser::Node.new(location: location, type: :test, answer: 42) }

  describe '#==' do
    specify { expect(node).to eq(Rip::Parser::Node.new(location: location, type: :test, answer: 42)) }
    specify { expect(node).to eq(location: location, type: :test, answer: 42) }
  end

  describe '#[]' do
    context 'responding to location' do
      specify { expect(node[:location]).to eq(location) }
    end

    context 'symbol key' do
      specify { expect(node[:answer]).to eq(42) }
    end

    context 'string key' do
      specify { expect(node['answer']).to eq(42) }
    end

    context 'missing key' do
      specify { expect(node[:other]).to be(nil) }
    end
  end

  describe '#each' do
    specify do
      expect do |x|
        node.each(&x)
      end.to yield_successive_args([ :location, location ], [ :type, :test ], [ :answer, 42 ])
    end
  end

  describe '#key?' do
    specify { expect(node.key?(:answer)).to be(true) }
    specify { expect(node.key?(:foo)).to be(false) }

    specify { expect(node.key?('answer')).to be(true) }
  end

  describe '#keys' do
    specify { expect(node.keys).to match_array([ :answer ]) }
  end

  describe '#length' do
    specify { expect(node.length).to eq(node.location.length) }
  end

  describe '#merge' do
    let(:other_location) { Rip::Parser::Location.new(:rspec, 1, 2, 1) }
    let(:other) { Rip::Parser::Node.new(location: other_location, type: :other_test, foo: :bar) }

    specify { expect(node.merge(foo: :bar)).to be_a(Rip::Parser::Node) }

    specify { expect(node.merge(answer: :bar).to_h).to eq(location: location, type: :test, answer: :bar) }
    specify { expect(node.merge(type: :baz, foo: :bar).to_h).to eq(location: location, type: :baz, answer: 42, foo: :bar) }

    specify { expect(node.merge(other).to_h).to eq(location: location, type: :other_test, answer: 42, foo: :bar) }
  end

  describe '#s_expression' do
    let(:tree) { Rip::Parser::Node.new(location: location, type: :root, children: [ node ]) }

    let(:expected) do
      {
        type: :root,
        children: [
          {
            type: :test,
            answer: 42
          }
        ]
      }
    end

    specify { expect(tree.s_expression).to eq(expected) }
    specify { expect(tree.s_expression).to be_a(Hash) }

    specify { expect(tree.s_expression.keys).to eq([ :type, :children ]) }

    specify { expect(tree.s_expression[:children].first).to be_a(Hash) }
  end

  describe '#to_h' do
    specify { expect(node.to_h.keys).to eq([ :location, :type, :answer ]) }

    context 'nested tree' do
      let(:tree) { Rip::Parser::Node.new(location: location, type: :root, other: node) }

      let(:expected) do
        {
          location: location,
          type: :root,
          other: {
            location: location,
            type: :test,
            answer: 42
          }
        }
      end

      specify { expect(tree.to_h).to eq(expected) }
      specify { expect(tree.to_h[:other]).to be_a(Hash) }
    end
  end

  describe '.new' do
    let(:tree) { Rip::Parser::Node.new(location: location, type: :root, nested: { location: location, type: :nested, foo: :bar }) }

    specify { expect(tree.nested).to be_a(Rip::Parser::Node) }
    specify { expect(tree.nested.foo).to eq(:bar) }
  end

  context 'dynamic message lookup' do
    specify { expect(node).to respond_to(:answer) }
    specify { expect(node).to_not respond_to(:foo) }

    specify { expect(node.answer).to eq(42) }
    specify { expect { node.foo }.to raise_error(NoMethodError) }
  end

  context 'nesting' do
    let(:root) { Rip::Parser::Node.new(location: location, type: :root, other: node) }

    specify { expect(root.other).to eq(node) }
    specify { expect(root.other.answer).to eq(42) }

    specify { expect(root).to be_root }
    specify { expect(root.type).to eq(:root) }

    specify { expect(root).to respond_to(:root?) }
    specify { expect(root).to respond_to(:test?) }

    context 'nested collection' do
      let(:nodes) do
        [
          Rip::Parser::Node.new(location: location, type: :nested, aaa: 111),
          Rip::Parser::Node.new(location: location, type: :special, bbb: 222),
          Rip::Parser::Node.new(location: location, type: :nested, ccc: 333)
        ]
      end

      let(:root) { Rip::Parser::Node.new(location: location, type: :root, others: nodes) }

      let(:filtered) { nodes.select(&:special?) }

      specify { expect(root.others.sample).to be_a(Rip::Parser::Node) }

      specify { expect(filtered.count).to eq(1) }
      specify { expect(filtered.first.type).to eq(:special) }
    end
  end
end
