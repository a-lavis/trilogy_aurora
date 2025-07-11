# frozen_string_literal: true

require_relative 'lib/trilogy_aurora/version'

Gem::Specification.new do |spec|
  spec.name = 'trilogy_aurora'
  spec.version = TrilogyAurora::VERSION
  spec.authors = ['Aidan Lavis']
  spec.email = ['aidanlavis@gmail.com']

  spec.summary = 'Adds AWS Aurora failover support to Trilogy.'
  # spec.description = "TODO: Write a longer description or delete this line."
  spec.homepage = 'https://github.com/a-lavis/trilogy_aurora'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.0.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.require_paths = ['lib']

  spec.add_dependency 'bigdecimal'
  spec.add_dependency 'trilogy', '>= 2.5'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end
