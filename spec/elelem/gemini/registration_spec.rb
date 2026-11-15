# frozen_string_literal: true

RSpec.describe "the gemini provider" do
  around do |example|
    saved = ENV.to_h.slice("GEMINI_API_KEY", "GEMINI_BASE_URL", "GEMINI_MODEL")
    example.run
  ensure
    %w[GEMINI_API_KEY GEMINI_BASE_URL GEMINI_MODEL].each { |k| ENV.delete(k) }
    ENV.update(saved)
  end

  before do
    ENV["GEMINI_API_KEY"] = "test-key"
    ENV["GEMINI_MODEL"] = "env-model"
    ENV.delete("GEMINI_BASE_URL")
  end

  def build(**) = Elelem::Config.build_provider("gemini", **)
  def uri(**) = build(**).instance_variable_get(:@uri).to_s
  def model(**) = build(**).instance_variable_get(:@model)

  it "registers provider gemini" do
    expect(Elelem::Config.names).to include("gemini")
    expect(build).to be_a(Elelem::OpenAI::Provider)
  end

  it "talks to Gemini by default" do
    expect(uri).to eq("https://generativelanguage.googleapis.com/v1beta/openai/chat/completions")
  end

  it "sends GEMINI_API_KEY" do
    expect(build.instance_variable_get(:@api_key)).to eq("test-key")
  end

  it "names GEMINI_API_KEY when the key is missing or empty" do
    ENV.delete("GEMINI_API_KEY")
    expect { build }.to raise_error(KeyError, /GEMINI_API_KEY/)

    ENV["GEMINI_API_KEY"] = " "
    expect { build }.to raise_error(KeyError, /GEMINI_API_KEY/)
  end

  it "names GEMINI_MODEL when no model is set, and treats an empty one as unset" do
    ENV.delete("GEMINI_MODEL")
    expect { build }.to raise_error(KeyError, /GEMINI_MODEL/)

    ENV["GEMINI_MODEL"] = ""
    expect { build }.to raise_error(KeyError, /GEMINI_MODEL/)
  end

  it "takes the model from GEMINI_MODEL" do
    expect(model).to eq("env-model")
  end

  it "prefers --model over GEMINI_MODEL" do
    expect(model(model: "flag-model")).to eq("flag-model")
  end

  it "uses GEMINI_BASE_URL, with or without a trailing slash, and treats an empty one as unset" do
    ENV["GEMINI_BASE_URL"] = "http://127.0.0.1:8080/v1/"
    expect(uri).to eq("http://127.0.0.1:8080/v1/chat/completions")

    ENV["GEMINI_BASE_URL"] = "http://127.0.0.1:8080/v1"
    expect(uri).to eq("http://127.0.0.1:8080/v1/chat/completions")

    ENV["GEMINI_BASE_URL"] = ""
    expect(uri).to eq("https://generativelanguage.googleapis.com/v1beta/openai/chat/completions")
  end
end
