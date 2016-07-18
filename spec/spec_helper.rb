require 'pry'

require_relative '../source/rip-parser'

pattern = Pathname.new(__dir__).join('support/**/*.rb')
Pathname.glob(pattern).each(&method(:require))

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus => true
  config.filter_run_excluding :blur => true

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.order = 'random'

  config.color = true
end
