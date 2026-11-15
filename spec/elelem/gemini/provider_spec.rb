# frozen_string_literal: true

RSpec.describe Elelem::Gemini::Provider do
  subject(:provider) do
    described_class.new(model: "gemini-3.5-flash", api_key: "test-key", http:)
  end

  let(:messages) { [{ role: "user", content: "read README.md and Gemfile at the same time" }] }
  let(:signature) { { "google" => { "thought_signature" => "c2lnbmF0dXJl" } } }

  # Two tool calls in the shape Gemini streams them: no index, each whole in its own chunk,
  # and a thought signature on the first.
  let(:events) do
    [
      { "choices" => [{ "delta" => { "role" => "assistant", "tool_calls" => [
        { "extra_content" => signature, "id" => "call_1", "type" => "function",
          "function" => { "name" => "read", "arguments" => '{"path":"README.md"}' } }
      ] } }] },
      { "choices" => [{ "delta" => { "role" => "assistant", "tool_calls" => [
        { "id" => "call_2", "type" => "function",
          "function" => { "name" => "read", "arguments" => '{"path":"Gemfile"}' } }
      ] } }] },
      { "choices" => [{ "delta" => { "role" => "assistant" }, "finish_reason" => "stop" }] }
    ]
  end

  let(:http) do
    Class.new do
      attr_reader :bodies

      def initialize(chunk)
        @chunk = chunk
        @bodies = []
      end

      def post(_uri, body:, **)
        @bodies << body
        response = Net::HTTPOK.new("1.1", "200", "OK")
        chunk = @chunk
        response.define_singleton_method(:read_body) { |&block| block.call(chunk) }
        yield response
      end
    end.new(sse(events))
  end

  def sse(events)
    events.map { |event| "data: #{JSON.generate(event)}\n" }.join << "data: [DONE]\n"
  end

  it "keeps parallel tool calls apart when they carry no index" do
    calls = provider.fetch(messages, []) {}

    expect(calls).to eq(
      [
        { id: "call_1", name: "read", arguments: { "path" => "README.md" } },
        { id: "call_2", name: "read", arguments: { "path" => "Gemfile" } }
      ]
    )
  end

  context "when a call's arguments arrive in pieces with no id" do
    let(:events) do
      [
        { "choices" => [{ "delta" => { "tool_calls" => [
          { "id" => "call_1", "function" => { "name" => "read", "arguments" => '{"path":"README.md"}' } }
        ] } }] },
        { "choices" => [{ "delta" => { "tool_calls" => [
          { "id" => "call_2", "function" => { "name" => "read", "arguments" => '{"path":' } },
          { "function" => { "arguments" => '"Gem' } }
        ] } }] },
        { "choices" => [{ "delta" => { "tool_calls" => [{ "function" => { "arguments" => 'file"}' } }] } }] }
      ]
    end

    it "joins each piece to the call before it" do
      calls = provider.fetch(messages, []) {}

      expect(calls.map { |call| [call[:id], call[:arguments]] }).to eq(
        [["call_1", { "path" => "README.md" }], ["call_2", { "path" => "Gemfile" }]]
      )
    end
  end

  it "sends each tool call's thought signature back with it" do
    calls = provider.fetch(messages, []) {}
    history = messages + [
      { role: "assistant", content: "", tool_calls: calls },
      { role: "tool", tool_call_id: "call_1", content: "{}" },
      { role: "tool", tool_call_id: "call_2", content: "{}" }
    ]
    provider.fetch(history, []) {}

    sent = http.bodies.last[:messages][1][:tool_calls]
    expect(sent.map { |call| call[:extra_content] }).to eq([signature, nil])
  end
end
