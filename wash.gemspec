# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "wash"
  spec.version       = "0.4.0"
  spec.authors       = ["Puppet"]
  spec.email         = ["puppet@puppet.com"]

  spec.summary       = "A library for building Wash external plugins"
  spec.description   = "A library for building Wash external plugins"
  spec.homepage      = "https://github.com/puppetlabs/wash-ruby"
  spec.license       = "Apache-2.0"
  spec.files         = Dir['lib/**/*.rb']
  spec.require_paths = ["lib"]

  spec.required_ruby_version = "~> 2.3"
end
