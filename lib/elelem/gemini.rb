# frozen_string_literal: true

require "elelem/openai"

require_relative "gemini/version"
require_relative "gemini/provider"

Elelem.configure do |config|
  config.provider(:gemini) do |model: nil, **|
    # A variable that is set but empty counts as unset.
    env = ->(name) { ENV[name].to_s.strip.then { |v| v.empty? ? nil : v } }
    key = env.call("GEMINI_API_KEY")
    raise KeyError, "GEMINI_API_KEY is not set" if key.nil?

    model = env.call("GEMINI_MODEL") if model.to_s.strip.empty?
    raise KeyError, "GEMINI_MODEL is not set. Pass --model or set GEMINI_MODEL" if model.nil?

    Elelem::Gemini::Provider.new(
      model:,
      api_key: key,
      base_url: env.call("GEMINI_BASE_URL") || "https://generativelanguage.googleapis.com/v1beta/openai"
    )
  end
end
