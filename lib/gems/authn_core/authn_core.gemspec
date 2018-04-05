# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "authn_core/version"

Gem::Specification.new do |spec|
  spec.name          = "authn_core"
  spec.version       = AuthnCore::VERSION
  spec.authors       = ["Jason Vanderhoof", "Geri Jennings", "Jonah Goldstein"]
  spec.email         = ["jvanderhoof@gmail.com", "geri.jennings@cyberark.com", "jonah.goldstein@cyberark.com"]

  spec.summary       = %q{Conjur custom authenticator core requirements}
  spec.description   = "An implementation of the minimal security requirements for Conjur custom authenticators. All Conjur custom authenticators should make use of this core functionality."
  spec.homepage      = "https://github.com/cyberark/conjur/lib/gems/authn_core/README.md"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'conjur-api', '~> 5'

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
