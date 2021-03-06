# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rbar/version'

Gem::Specification.new do |spec|
  spec.name          = "rbar"
  spec.version       = Rbar::VERSION
  spec.authors       = ["Owen Stephens"]
  spec.email         = ["owen@owenstephens.co.uk"]

  spec.summary       = 'Ruby AST-based Refactoring'
  spec.description   = 'Ruby AST-based Refactoring'
  spec.homepage      = "https://github.com/owst/rbar"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "parser"
  spec.add_dependency "activesupport"
  spec.add_dependency "thor"

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 12.3", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.9"
  spec.add_development_dependency "pry-byebug", "~> 3.8"
end
