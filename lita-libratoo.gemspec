Gem::Specification.new do |spec|
  spec.name          = "lita-libratoo"
  spec.version       = "0.1.1"
  spec.authors       = ["Eric Boehs"]
  spec.email         = ["ericboehs@gmail.com"]
  spec.description   = "Query librato metrics from Lita"
  spec.summary       = "Query librato metrics from Lita"
  spec.homepage      = "https://github.com/ericboehs/lita-libratoo"
  spec.license       = "MIT"
  spec.metadata      = { "lita_plugin_type" => "handler" }

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "lita", ">= 4.7"
  spec.add_runtime_dependency "librato-metrics", "~> 1.6"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec", ">= 3.0.0"
end
