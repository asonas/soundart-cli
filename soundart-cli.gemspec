lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "soundart/version"

Gem::Specification.new do |spec|
  spec.name          = "soundart"
  spec.version       = Soundart::VERSION
  spec.authors       = ["Yuya Fujiwara"]
  spec.email         = ["asonas@cookpad.com"]

  spec.summary       = %q{Attach artwork to sound source}
  spec.description   = %q{no more unsigned artwork}
  spec.homepage      = "https://github.com/asonas/soundart-cli"
  spec.license       = "MIT"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "taglib-ruby"
  spec.add_dependency "soundcloud"

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
end
