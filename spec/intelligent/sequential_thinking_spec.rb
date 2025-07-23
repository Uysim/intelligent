# frozen_string_literal: true

RSpec.describe Intelligent::SequentialThinking do
  describe "#initialize" do
    it "can be instantiated" do
      expect { described_class.new }.not_to raise_error
    end

    it "uses default model" do
      instance = described_class.new
      expect(instance.instance_variable_get(:@model)).to eq("claude-sonnet-4-20250514")
    end

    it "accepts custom model" do
      instance = described_class.new(model: "claude-opus-4-20250514")
      expect(instance.instance_variable_get(:@model)).to eq("claude-opus-4-20250514")
    end

    it "creates Anthropic service with model" do
      instance = described_class.new(model: "claude-3-5-haiku-20241022")
      anthropic_service = instance.instance_variable_get(:@anthropic_service)
      expect(anthropic_service).to be_a(Intelligent::Llm::Anthropic)
      expect(anthropic_service.instance_variable_get(:@model)).to eq("claude-3-5-haiku-20241022")
    end
  end

  describe "#think_through_problem" do
    let(:problem_description) { "How do I implement a binary search algorithm?" }
    let(:files) { [] }
    let(:max_thoughts) { 3 }

    context "when thinking process succeeds" do
      let(:mock_response) do
        {
          success: true,
          text: "This is a thought step",
          usage: { input_tokens: 10, output_tokens: 20 }
        }
      end

      it "returns success with thoughts and final answer" do
        llm_service = instance_double(Intelligent::Llm::Anthropic)
        allow(Intelligent::Llm::Anthropic).to receive(:new).with(model: "claude-sonnet-4-20250514").and_return(llm_service)
        allow(llm_service).to receive(:generate).and_return(mock_response)

        instance = described_class.new
        result = instance.think_through_problem(problem_description, files, max_thoughts)

        expect(result[:success]).to be true
        expect(result[:thoughts]).to be_an(Array)
        expect(result[:thoughts].length).to eq(max_thoughts)
        expect(result[:final_text]).to eq("This is a thought step")
      end

      it "calls anthropic service for each thought step" do
        llm_service = instance_double(Intelligent::Llm::Anthropic)
        allow(Intelligent::Llm::Anthropic).to receive(:new).with(model: "claude-sonnet-4-20250514").and_return(llm_service)
        allow(llm_service).to receive(:generate).and_return(mock_response)

        instance = described_class.new
        instance.think_through_problem(problem_description, files, max_thoughts)

        # Should be called for each thought step plus final answer
        expect(llm_service).to have_received(:generate).exactly(max_thoughts + 1).times
      end

      it "builds thoughts with correct structure" do
        llm_service = instance_double(Intelligent::Llm::Anthropic)
        allow(Intelligent::Llm::Anthropic).to receive(:new).with(model: "claude-sonnet-4-20250514").and_return(llm_service)
        allow(llm_service).to receive(:generate).and_return(mock_response)

        instance = described_class.new
        result = instance.think_through_problem(problem_description, files, max_thoughts)

        result[:thoughts].each_with_index do |thought, index|
          expect(thought[:number]).to eq(index + 1)
          expect(thought[:content]).to eq("This is a thought step")
          expect(thought[:timestamp]).to be_a(Time)
        end
      end

      it "passes files to anthropic service" do
        test_files = [double("file1"), double("file2")]
        llm_service = instance_double(Intelligent::Llm::Anthropic)
        allow(Intelligent::Llm::Anthropic).to receive(:new).with(model: "claude-sonnet-4-20250514").and_return(llm_service)
        allow(llm_service).to receive(:generate).and_return(mock_response)

        instance = described_class.new
        instance.think_through_problem(problem_description, test_files, max_thoughts)

        expect(llm_service).to have_received(:generate).with(anything, test_files).at_least(:once)
      end
    end

    context "when thinking process fails during thought generation" do
      let(:mock_response) do
        {
          success: false,
          error: "API request failed: Rate limit exceeded"
        }
      end

      it "returns failure with error message" do
        llm_service = instance_double(Intelligent::Llm::Anthropic)
        allow(Intelligent::Llm::Anthropic).to receive(:new).with(model: "claude-sonnet-4-20250514").and_return(llm_service)
        allow(llm_service).to receive(:generate).and_return(mock_response)

        instance = described_class.new
        result = instance.think_through_problem(problem_description, files, max_thoughts)

        expect(result[:success]).to be false
        expect(result[:error]).to eq("API request failed: Rate limit exceeded")
      end
    end

    context "when final answer generation fails" do
      let(:thinking_response) do
        {
          success: true,
          text: "This is a thought step",
          usage: { input_tokens: 10, output_tokens: 20 }
        }
      end

      let(:final_answer_response) do
        {
          success: false,
          error: "Failed to generate final answer"
        }
      end

      it "returns failure with error message" do
        llm_service = instance_double(Intelligent::Llm::Anthropic)
        allow(Intelligent::Llm::Anthropic).to receive(:new).with(model: "claude-sonnet-4-20250514").and_return(llm_service)
        allow(llm_service).to receive(:generate)
          .and_return(thinking_response, thinking_response, thinking_response, final_answer_response)

        instance = described_class.new
        result = instance.think_through_problem(problem_description, files, max_thoughts)

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Failed to generate final answer")
      end
    end

    context "when thought indicates completion early" do
      let(:thinking_response) do
        {
          success: true,
          text: "This is a thought step",
          usage: { input_tokens: 10, output_tokens: 20 }
        }
      end

      let(:completion_thought) do
        {
          success: true,
          text: "Therefore, the conclusion is to use binary search with O(log n) complexity",
          usage: { input_tokens: 10, output_tokens: 20 }
        }
      end

      let(:final_answer_response) do
        {
          success: true,
          text: "Final answer",
          usage: { input_tokens: 10, output_tokens: 20 }
        }
      end

      it "stops generating thoughts when conclusion is reached" do
        llm_service = instance_double(Intelligent::Llm::Anthropic)
        allow(Intelligent::Llm::Anthropic).to receive(:new).with(model: "claude-sonnet-4-20250514").and_return(llm_service)
        allow(llm_service).to receive(:generate)
          .and_return(thinking_response, completion_thought, final_answer_response)

        instance = described_class.new
        result = instance.think_through_problem(problem_description, files, max_thoughts)

        expect(result[:success]).to be true
        expect(result[:thoughts].length).to eq(2) # Should stop after second thought
      end
    end

    context "with different max_thoughts values" do
      let(:mock_response) do
        {
          success: true,
          text: "This is a thought step",
          usage: { input_tokens: 10, output_tokens: 20 }
        }
      end

      it "respects max_thoughts parameter" do
        llm_service = instance_double(Intelligent::Llm::Anthropic)
        allow(Intelligent::Llm::Anthropic).to receive(:new).with(model: "claude-sonnet-4-20250514").and_return(llm_service)
        allow(llm_service).to receive(:generate).and_return(mock_response)

        instance = described_class.new
        result = instance.think_through_problem(problem_description, files, 1)

        expect(result[:thoughts].length).to eq(1)
      end

      it "uses default max_thoughts when not specified" do
        llm_service = instance_double(Intelligent::Llm::Anthropic)
        allow(Intelligent::Llm::Anthropic).to receive(:new).with(model: "claude-sonnet-4-20250514").and_return(llm_service)
        allow(llm_service).to receive(:generate).and_return(mock_response)

        instance = described_class.new
        result = instance.think_through_problem(problem_description, files)

        expect(result[:thoughts].length).to eq(5) # Default value
      end
    end
  end

  describe "private methods" do
    let(:instance) { described_class.new }

    describe "#build_thinking_prompt" do
      it "builds prompt with problem description" do
        problem = "Test problem"
        thoughts = []
        current_thought = 1
        total_thoughts = 3

        prompt = instance.send(:build_thinking_prompt, problem, thoughts, current_thought, total_thoughts)

        expect(prompt).to include("Problem: Test problem")
        expect(prompt).to include("Thought 1 of 3")
      end

      it "includes previous thoughts when available" do
        problem = "Test problem"
        thoughts = [
          { number: 1, content: "First thought", timestamp: Time.now },
          { number: 2, content: "Second thought", timestamp: Time.now }
        ]
        current_thought = 3
        total_thoughts = 3

        prompt = instance.send(:build_thinking_prompt, problem, thoughts, current_thought, total_thoughts)

        expect(prompt).to include("Thought 1: First thought")
        expect(prompt).to include("Thought 2: Second thought")
        expect(prompt).to include("Thought 3 of 3")
      end
    end

    describe "#analyze_thought_completeness" do
      it "returns false when thought contains conclusion indicators" do
        thought_content = "Therefore, the answer is X"
        current_thought = 2
        total_thoughts = 5

        result = instance.send(:analyze_thought_completeness, thought_content, current_thought, total_thoughts)

        expect(result).to be false
      end

      it "returns false when max thoughts reached" do
        thought_content = "This is just a regular thought"
        current_thought = 5
        total_thoughts = 5

        result = instance.send(:analyze_thought_completeness, thought_content, current_thought, total_thoughts)

        expect(result).to be false
      end

      it "returns true when thought is incomplete and not at max" do
        thought_content = "This is just a regular thought"
        current_thought = 2
        total_thoughts = 5

        result = instance.send(:analyze_thought_completeness, thought_content, current_thought, total_thoughts)

        expect(result).to be true
      end

      it "detects various conclusion indicators" do
        conclusion_indicators = ["conclusion", "final answer", "summary", "therefore", "thus", "in conclusion"]
        
        conclusion_indicators.each do |indicator|
          thought_content = "This is the #{indicator} of our analysis"
          result = instance.send(:analyze_thought_completeness, thought_content, 2, 5)
          expect(result).to be false
        end
      end
    end

    describe "#generate_final_answer" do
      let(:problem_description) { "How do I implement a binary search?" }
      let(:thoughts) do
        [
          { number: 1, content: "First step", timestamp: Time.now },
          { number: 2, content: "Second step", timestamp: Time.now }
        ]
      end
      let(:files) { [] }

      context "when final answer generation succeeds" do
        let(:mock_response) do
          {
            success: true,
            text: "Use binary search with O(log n) complexity",
            usage: { input_tokens: 10, output_tokens: 20 }
          }
        end

        it "returns success with final answer" do
          llm_service = instance_double(Intelligent::Llm::Anthropic)
          allow(Intelligent::Llm::Anthropic).to receive(:new).with(model: "claude-sonnet-4-20250514").and_return(llm_service)
          allow(llm_service).to receive(:generate).and_return(mock_response)

          result = instance.send(:generate_final_answer, problem_description, thoughts, files)

          expect(result[:success]).to be true
          expect(result[:text]).to eq("Use binary search with O(log n) complexity")
        end

        it "calls anthropic service with final answer prompt" do
          llm_service = instance_double(Intelligent::Llm::Anthropic)
          allow(Intelligent::Llm::Anthropic).to receive(:new).with(model: "claude-sonnet-4-20250514").and_return(llm_service)
          allow(llm_service).to receive(:generate).and_return(mock_response)

          instance.send(:generate_final_answer, problem_description, thoughts, files)

          expect(llm_service).to have_received(:generate).with(
            include("Based on your step-by-step thinking process"),
            files
          )
        end
      end

      context "when final answer generation fails" do
        let(:mock_response) do
          {
            success: false,
            error: "Failed to generate final answer"
          }
        end

        it "returns failure with error" do
          llm_service = instance_double(Intelligent::Llm::Anthropic)
          allow(Intelligent::Llm::Anthropic).to receive(:new).with(model: "claude-sonnet-4-20250514").and_return(llm_service)
          allow(llm_service).to receive(:generate).and_return(mock_response)

          result = instance.send(:generate_final_answer, problem_description, thoughts, files)

          expect(result[:success]).to be false
          expect(result[:error]).to eq("Failed to generate final answer")
        end
      end
    end
  end
end 