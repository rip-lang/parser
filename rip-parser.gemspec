require_relative './source/rip/parser/about'

Gem::Specification.new do |spec|
  spec.name          = 'rip-parser'
  spec.version       = Rip::Parser::About.version
  spec.author        = 'Thomas Ingram'
  spec.license       = 'MIT'
  spec.summary       = 'Composable parser for Rip'
  spec.homepage      = 'http://www.rip-lang.org/'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.require_paths = [ 'source' ]

  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-doc'
  spec.add_development_dependency 'pry-rescue'
  spec.add_development_dependency 'pry-stack_explorer'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'ruby-prof'

  spec.add_runtime_dependency 'parslet', '~> 1.7.0'
end
