lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "one_authentication/version"

Gem::Specification.new do |spec|
  spec.name          = "one_authentication"
  spec.version       = OneAuthentication::VERSION
  spec.authors       = ["anoymouscoder"]
  spec.email         = ["809532742@qq.com"]

  spec.summary       = "One authentication client ruby sdk"
  spec.description   = "One authentication client ruby sdk"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", ">= 12.3.3"
end
