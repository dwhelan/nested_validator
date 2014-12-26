# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'nested_validator/version'

Gem::Specification.new do |spec|
  spec.name          = 'nested_validator'
  spec.version       = NestedValidator::VERSION
  spec.authors       = ['Declan Whelan']
  spec.email         = ['declanpwhelan@gmail.com']
  spec.summary       = 'A validator that supports nesting.'
  spec.description   = "Nested validations allow a parent's validity to include those of child attributes. Errors messages will be copied from the child attribute to the parent."
  spec.homepage      = 'https://github.com/dwhelan/nested_validator'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activemodel'
  spec.add_dependency 'activesupport'

  #spec.add_development_dependency 'awesome_print'
  #spec.add_development_dependency 'pry'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-its'
  spec.add_development_dependency 'coveralls'
end
