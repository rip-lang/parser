require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Module do
  class ModuleParser
    include Rip::Parser::Rules::Module
  end

  let(:parser) { ModuleParser.new }

  describe '#module' do
    subject { parser.module }
  end
end
