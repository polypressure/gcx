# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gcx/version'

Gem::Specification.new do |spec|
  spec.name          = "gcx"
  spec.version       = GCX::VERSION
  spec.authors       = ["Anthony Garcia"]
  spec.email         = ["anthony.garcia@outlook.com"]

  spec.summary       = %q{Raise Giftcard Marketplace Coding Exercise.}
  spec.summary       = "Raise Giftcard Marketplace Coding Exercise"
  spec.description   = "Raise Giftcard Marketplace Coding Exercise"
  spec.homepage      = "https://bitbucket.org/polypressure/gcx"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://dByxTkHpV3u7z3kGDTEw@gem.fury.io/polypressure/"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.required_ruby_version = '~> 2.2'

  spec.add_runtime_dependency 'moneta'
  spec.add_runtime_dependency 'money'
  spec.add_runtime_dependency 'monetize'
  spec.add_runtime_dependency 'pry'
  spec.add_runtime_dependency 'ruby-progressbar'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'minitest', '~> 5.5'
  spec.add_development_dependency 'm', '~> 1.3', '>= 1.3.1'
  spec.add_development_dependency 'minitest-reporters', '~> 1.0', '>= 1.0.19'
  spec.add_development_dependency 'mocha', '~> 1.1'
  spec.add_development_dependency 'simplecov', '~> 0.10.0'
  spec.add_development_dependency 'faker'

end
