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

  spec.add_runtime_dependency 'hashie'
  spec.add_runtime_dependency 'parslet', '~> 1.7.0'

  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'pry-doc'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
