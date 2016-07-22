require 'spec_helper'

RSpec.describe Rip::Parser do
  describe '.load' do
  end

  describe '.load_file' do
  end

  describe '.root' do
    specify { expect(Rip::Parser.root).to eq(Pathname.new(__dir__).parent.parent.parent.expand_path) }
  end
end
