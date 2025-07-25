# frozen_string_literal: true

require_relative "lib/intelligent/version"

Gem::Specification.new do |spec|
  spec.name = "intelligent"
  spec.version = Intelligent::VERSION
  spec.authors = ["Uysim"]
  spec.email = ["uysimty@gmail.com"]

  spec.summary = "Add intelligent to your Ruby engine"
  spec.description = "Add intelligent to your Ruby engine"
  spec.homepage = "https://github.com/uysim/intelligent"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/uysim/intelligent"
  spec.metadata["changelog_uri"] = "https://github.com/uysim/intelligent/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html

  spec.add_dependency "anthropic", ">= 1.1"
  spec.add_dependency "pry", "~> 0.14.1"
  spec.add_development_dependency "rspec", "~> 3.12"

end
