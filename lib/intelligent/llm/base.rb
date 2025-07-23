module Intelligent
  module Llm
    class Base
      attr_reader :provider, :model

      def initialize(provider: "anthropic", model: "claude-sonnet-4-20250514")
        @provider = provider
        @model = model
      end

      def generate(prompt_content, files = [])
        raise NotImplementedError, "Subclasses must implement generate method"
      end

      protected

      def api_key
        case provider
        when "anthropic"
          ENV["ANTHROPIC_API_KEY"]
        else
          raise ArgumentError, "Unsupported provider: #{provider}"
        end
      end

      def api_key_present?
        !api_key.nil? && !api_key.empty?
      end
    end
  end
end