# frozen_string_literal: true

require_relative "lib/elelem/gemini/version"

Gem::Specification.new do |spec|
  spec.name = "elelem-gemini"
  spec.version = Elelem::Gemini::VERSION
  spec.authors = ["mo khan"]
  spec.email = ["mo@mokhan.ca"]

  spec.summary = "A Google Gemini provider plugin for elelem."
  spec.description = "A Google Gemini provider plugin for elelem."
  spec.homepage = "https://elelem.sh"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 4.0.0"
  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/elelem-sh/gemini"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["LICENSE.txt", "lib/**/*.rb", "exe/*"]
  spec.bindir = "exe"
  spec.executables = ["elelem-gemini"]
  spec.require_paths = ["lib"]

  spec.add_dependency "elelem-openai", ">= 0.3", "< 1"
end
