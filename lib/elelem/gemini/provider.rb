# frozen_string_literal: true

module Elelem
  module Gemini
    # Gemini's OpenAI-compatible endpoint differs from Chat Completions in two ways:
    #
    # * Streamed tool calls carry no `index`. Each call arrives whole, with its own `id`.
    # * A tool call may carry `extra_content.google.thought_signature`, which Gemini 3
    #   models require back on that tool call in the next request, or they answer 400.
    class Provider < Elelem::OpenAI::Provider
      def initialize(...)
        super
        @extra_content = {}
      end

      private

      def build_request_body(messages, tools)
        body = super
        body.merge(messages: body[:messages].map { |message| with_extra_content(message) })
      end

      def with_extra_content(message)
        calls = message[:tool_calls]
        return message unless calls

        message.merge(tool_calls: calls.map { |call| with_signature(call) })
      end

      def with_signature(call)
        extra = @extra_content[call[:id]]
        extra ? call.merge(extra_content: extra) : call
      end

      def accumulate_tool_calls(incoming_tool_calls, tool_calls)
        # A chunk with no id continues the call before it, even within one delta.
        last = tool_calls.keys.last
        incoming = incoming_tool_calls.map do |tool_call|
          id = tool_call["id"]
          @extra_content[id] = tool_call["extra_content"] if id && tool_call["extra_content"]
          next tool_call if tool_call.key?("index")

          last = id if id
          tool_call.merge("index" => last)
        end
        super(incoming, tool_calls)
      end
    end
  end
end
