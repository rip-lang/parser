require 'spec_helper'

RSpec.describe Rip::Parser::Rules::Assignment do
  class AssignmentParser
    include Rip::Parser::Rules::Character
  end

  let(:parser) { AssignmentParser.new }

  describe '#assignment' do
    subject { parser.assignment }
  end
end
