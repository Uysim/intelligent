# frozen_string_literal: true

RSpec.describe Intelligent::Generation do
  describe "#initialize" do
    it "can be instantiated with required parameters" do
      expect { described_class.new("test prompt", {}, "claude-sonnet-4-20250514", false) }.not_to raise_error
    end

    it "creates a Prompt instance" do
      generation = described_class.new("test prompt", {}, "claude-sonnet-4-20250514", false)
      expect(generation.prompt).to be_a(Intelligent::Prompt)
    end
  end

  describe "#call" do
    let(:prompt) { "Generate a response for {{input}}" }
    let(:input_variables) { { "input" => "test data" } }
    let(:model) { "claude-sonnet-4-20250514" }
    let(:files) { [] }

    context "when use_sequential_thinking is false" do
      let(:generation) { described_class.new(prompt, input_variables, model, false, files) }

      before do
        allow_any_instance_of(Intelligent::Llm::Anthropic).to receive(:generate).and_return(mock_response)
      end

      context "when LLM generation succeeds" do
        let(:mock_response) do
          {
            success: true,
            text: "Generated response content",
            usage: { input_tokens: 10, output_tokens: 20 }
          }
        end

        it "returns success with generation result" do
          result = generation.call

          expect(result[:success]).to be true
        end

        it "calls the LLM service with processed content and files" do
          llm_service = instance_double(Intelligent::Llm::Anthropic)
          allow(Intelligent::Llm::Anthropic).to receive(:new).with(model: model).and_return(llm_service)
          allow(llm_service).to receive(:generate).and_return(mock_response)

          result = generation.call

          expect(llm_service).to have_received(:generate).with("Generate a response for test data", files)
          expect(result[:generated_text]).to eq("Generated response content")
        end
      end

      context "when LLM generation fails" do
        let(:mock_response) do
          {
            success: false,
            error: "API request failed: Rate limit exceeded"
          }
        end

        it "returns failure with error message" do
          result = generation.call

          expect(result[:success]).to be false
          expect(result[:error]).to eq("API request failed: Rate limit exceeded")
          expect(result[:generation]).to be_nil # @generation is not defined in the class
        end
      end

      context "when LLM service returns API error" do
        let(:mock_response) do
          {
            error: "API key not configured"
          }
        end

        it "returns failure with error message" do
          result = generation.call

          expect(result[:success]).to be false
          expect(result[:error]).to eq("API key not configured")
        end
      end
    end

    context "when use_sequential_thinking is true" do
      let(:generation) { described_class.new(prompt, input_variables, model, true, files) }

      before do
        allow_any_instance_of(Intelligent::SequentialThinking).to receive(:think_through_problem).and_return(mock_response)
      end

      context "when sequential thinking succeeds" do
        let(:mock_response) do
          {
            success: true,
            final_text: "Generated response content",
            thoughts: ["Step 1: Analyze the problem", "Step 2: Generate solution"]
          }
        end

        it "returns success with thinking process" do
          result = generation.call

          expect(result[:success]).to be true
          expect(result[:generated_text]).to eq("Generated response content")
          expect(result[:thoughts]).to eq(["Step 1: Analyze the problem", "Step 2: Generate solution"])
        end
      end

      context "when sequential thinking fails" do
        let(:mock_response) do
          {
            success: false,
            error: "Thinking process failed"
          }
        end

        it "returns failure with error message" do
          result = generation.call

          expect(result[:success]).to be false
          expect(result[:error]).to eq("Thinking process failed")
        end
      end
    end

    context "when an unexpected error occurs" do
      let(:generation) { described_class.new(prompt, input_variables, model, false, files) }

      before do
        allow_any_instance_of(Intelligent::Llm::Anthropic).to receive(:generate).and_raise(StandardError, "Unexpected error")
      end

      it "returns failure with error message" do
        result = generation.call

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Unexpected error")
      end
    end
  end

  describe "private methods" do
    let(:generation) { described_class.new("test prompt", {}, "claude-sonnet-4-20250514", false) }

    describe "#generate_with_llm" do
      let(:processed_content) { "Processed prompt content" }
      let(:all_files) { [] }

      before do
        allow_any_instance_of(Intelligent::Llm::Anthropic).to receive(:generate).and_return(mock_response)
      end

      context "when LLM generation succeeds" do
        let(:mock_response) do
          {
            success: true,
            text: "Generated response",
            usage: { input_tokens: 5, output_tokens: 10 }
          }
        end

        it "returns success result" do
          result = generation.send(:generate_with_llm, processed_content, all_files)

          expect(result[:success]).to be true
          expect(result[:generation]).to be_nil # @generation is not defined
        end

        it "calls LLM service with correct parameters" do
          llm_service = instance_double(Intelligent::Llm::Anthropic)
          allow(Intelligent::Llm::Anthropic).to receive(:new).with(model: "claude-sonnet-4-20250514").and_return(llm_service)
          allow(llm_service).to receive(:generate).and_return(mock_response)

          generation.send(:generate_with_llm, processed_content, all_files)

          expect(llm_service).to have_received(:generate).with(processed_content, all_files)
        end
      end

      context "when LLM generation fails" do
        let(:mock_response) do
          {
            success: false,
            error: "Generation failed"
          }
        end

        it "returns failure result" do
          result = generation.send(:generate_with_llm, processed_content, all_files)

          expect(result[:success]).to be false
          expect(result[:error]).to eq("Generation failed")
        end
      end

      context "when LLM service returns error directly" do
        let(:mock_response) do
          {
            error: "API key not configured"
          }
        end

        it "returns failure result" do
          result = generation.send(:generate_with_llm, processed_content, all_files)

          expect(result[:success]).to be false
          expect(result[:error]).to eq("API key not configured")
        end
      end
    end
  end
end 