# frozen_string_literal: true

require_relative "lib/blockster/version"

Gem::Specification.new do |spec|
  spec.name = "blockster"
  spec.version = Blockster::VERSION
  spec.authors = ["Toby"]
  spec.email = ["toby@darkroom.tech"]

  spec.summary = "Wrap classes in a block for easy access"
  spec.homepage = "https://github.com/tobyond/blockster"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "zeitwerk", "~> 2.6"
  spec.add_development_dependency "activemodel", "~> 7.0"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "sqlite3"
end
