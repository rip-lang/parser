module Rip::Parser
  module Rules
  end
end

pattern = Pathname.new(__dir__).join('rules/*.rb')
Pathname.glob(pattern).each(&method(:require))
