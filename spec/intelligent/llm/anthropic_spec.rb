# frozen_string_literal: true

require "base64"

RSpec.describe Intelligent::Llm::Anthropic do
  describe "#initialize" do
    it "can be instantiated" do
      expect { described_class.new }.not_to raise_error
    end

    it "uses default model" do
      instance = described_class.new
      expect(instance.model).to eq("claude-sonnet-4-20250514")
    end
  end

  describe ".available_models" do
    it "returns a hash of available models" do
      models = described_class.available_models
      expect(models).to be_a(Hash)
      expect(models).to include("claude-sonnet-4-20250514")
    end
  end

  describe "#generate" do
    let(:anthropic) { described_class.new }
    let(:mock_client) { instance_double(::Anthropic::Client) }
    let(:mock_response) { instance_double(::Anthropic::Message) }
    let(:mock_content) { instance_double(::Anthropic::TextBlock) }
    let(:mock_usage) { instance_double(::Anthropic::Usage) }

    before do
      allow(::Anthropic::Client).to receive(:new).and_return(mock_client)
      allow(mock_response).to receive(:content).and_return([mock_content])
      allow(mock_content).to receive(:text).and_return("Generated response")
      allow(mock_usage).to receive(:to_h).and_return({ "input_tokens" => 10, "output_tokens" => 20 })
      allow(mock_response).to receive(:usage).and_return(mock_usage)
    end

    context "when API key is not configured" do
      before do
        allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return(nil)
      end

      it "raises error when API key is missing" do
        expect {
          anthropic.generate("test prompt")
        }.to raise_error(ArgumentError, "API key not configured")
      end
    end

    context "when API key is configured" do
      before do
        allow(ENV).to receive(:[]).with("ANTHROPIC_API_KEY").and_return("test_key")
      end

      it "generates response successfully" do
        expect(mock_client).to receive(:messages).and_return(
          double(create: mock_response)
        )

        result = anthropic.generate("test prompt")

        expect(result).to eq({
          success: true,
          text: "Generated response",
          usage: { "input_tokens" => 10, "output_tokens" => 20 }
        })
      end

      it "calls API with correct parameters" do
        messages_double = double
        expect(mock_client).to receive(:messages).and_return(messages_double)
        expect(messages_double).to receive(:create).with(
          model: "claude-sonnet-4-20250514",
          max_tokens: 4000,
          messages: [
            {
              role: "user",
              content: [{ type: "text", text: "test prompt" }]
            }
          ]
        ).and_return(mock_response)

        anthropic.generate("test prompt")
      end

      context "with files" do
        let(:text_file) { instance_double(File, path: "/tmp/test.txt", read: "file content") }
        let(:image_file) { instance_double(File, path: "/tmp/test.jpg", read: "image_data") }
        let(:pdf_file) { instance_double(File, path: "/tmp/test.pdf", read: "pdf_data") }

        before do
          allow(Base64).to receive(:strict_encode64).and_return("encoded_data")
        end

        it "handles text files" do
          messages_double = double
          expect(mock_client).to receive(:messages).and_return(messages_double)
          expect(messages_double).to receive(:create).with(
            model: "claude-sonnet-4-20250514",
            max_tokens: 4000,
            messages: [
              {
                role: "user",
                content: [
                  { type: "text", text: "test prompt" },
                  { type: "text", text: "file content" }
                ]
              }
            ]
          ).and_return(mock_response)

          anthropic.generate("test prompt", [text_file])
        end

        it "handles image files" do
          messages_double = double
          expect(mock_client).to receive(:messages).and_return(messages_double)
          expect(messages_double).to receive(:create).with(
            model: "claude-sonnet-4-20250514",
            max_tokens: 4000,
            messages: [
              {
                role: "user",
                content: [
                  { type: "text", text: "test prompt" },
                  {
                    type: "image",
                    source: {
                      type: "base64",
                      media_type: "image/jpeg",
                      data: "encoded_data"
                    }
                  }
                ]
              }
            ]
          ).and_return(mock_response)

          anthropic.generate("test prompt", [image_file])
        end

        it "handles PDF files" do
          messages_double = double
          expect(mock_client).to receive(:messages).and_return(messages_double)
          expect(messages_double).to receive(:create).with(
            model: "claude-sonnet-4-20250514",
            max_tokens: 4000,
            messages: [
              {
                role: "user",
                content: [
                  { type: "text", text: "test prompt" },
                  {
                    type: "document",
                    source: {
                      type: "base64",
                      media_type: "application/pdf",
                      data: "encoded_data"
                    }
                  }
                ]
              }
            ]
          ).and_return(mock_response)

          anthropic.generate("test prompt", [pdf_file])
        end

        it "raises error for unsupported file types" do
          unsupported_file = instance_double(File, path: "/tmp/test.zip", read: "zip_data")

          expect {
            anthropic.generate("test prompt", [unsupported_file])
          }.to raise_error("Unsupported file type: application/octet-stream for file: /tmp/test.zip")
        end
      end

      context "when API request fails" do
        it "handles API errors" do
          messages_double = double
          expect(mock_client).to receive(:messages).and_return(messages_double)
          expect(messages_double).to receive(:create).and_raise(::Anthropic::Errors::APIError.new(url: "https://api.anthropic.com", message: "API error", status: 400))

          result = anthropic.generate("test prompt")

          expect(result).to eq({
            error: "API request failed: API error",
            status: 400
          })
        end

        it "handles general errors" do
          messages_double = double
          expect(mock_client).to receive(:messages).and_return(messages_double)
          expect(messages_double).to receive(:create).and_raise(StandardError.new("General error"))

          result = anthropic.generate("test prompt")

          expect(result).to eq({
            error: "Request failed: General error"
          })
        end
      end
    end
  end
end 