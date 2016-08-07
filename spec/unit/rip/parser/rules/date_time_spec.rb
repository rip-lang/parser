require 'spec_helper'

RSpec.describe Rip::Parser::Rules::DateTime do
  class DateTimeParser
    include Rip::Parser::Rules::DateTime
  end

  let(:parser) { DateTimeParser.new }

  describe '#date_time' do
    subject { parser.date_time }

    it do
      should parse('2012-02-12T21:51:50').as(
        date: { year: '2012', month: '02', day: '12' },
        time: { hour: '21', minute: '51', second: '50' }
      )
    end
  end

  describe '#date' do
    subject { parser.date }

    it { should parse('2012-02-12').as(year: '2012', month: '02', day: '12') }
  end

  describe '#time' do
    subject { parser.time }

    it { should parse('21:51:50').as(hour: '21', minute: '51', second: '50') }

    it { should parse('12:34:45.678').as(hour: '12', minute: '34', second: '45', sub_second: '678') }

    it do
      should parse('12:34:45-0500').as(
        hour: '12',
        minute: '34',
        second: '45',
        offset: {
          sign: '-',
          hour: '05',
          minute: '00'
        }
      )
    end

    it do
      should parse('12:34:45.678+1230').as(
        hour: '12',
        minute: '34',
        second: '45',
        sub_second: '678',
        offset: {
          sign: '+',
          hour: '12',
          minute: '30'
        }
      )
    end
  end
end
