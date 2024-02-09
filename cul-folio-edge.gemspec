require_relative 'lib/cul/folio/edge/version'

Gem::Specification.new do |spec|
  spec.name          = "cul-folio-edge"
  spec.version       = Cul::Folio::Edge::VERSION
  spec.authors       = ["Matthew Connolly"]
  spec.email         = ["mjc12@cornell.edu"]

  spec.summary       = "Connect to FOLIO Edge APIs"
  spec.description   = "Connect to FOLIO Edge APIs"
  spec.homepage      = "https://www.library.cornell.edu"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cul-it/cul-folio-edge"
  spec.metadata["changelog_uri"] = "https://github.com/cul-it/cul-folio-edge"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'rest-client'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'vcr'
end
