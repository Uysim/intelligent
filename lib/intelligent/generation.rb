require_relative "prompt"
require_relative "sequential_thinking"
require_relative "llm/anthropic"

module Intelligent
  class Generation
    attr_reader :prompt, :input_variables, :model, :use_sequential_thinking, :files

    def initialize(prompt, input_variables, llm_model, use_sequential_thinking = false, files = nil)
      @prompt = Prompt.new(prompt)
      @input_variables = input_variables
      @prompt.validate_variables!(@input_variables)

      @model = llm_model
      @use_sequential_thinking = use_sequential_thinking
      @files = files
    end

    def call
      @generated_prompt = @prompt.process_content(@input_variables)
  
      begin
        return generate_with_sequential_thinking(@generated_prompt, files) if @use_sequential_thinking
          
        generate_with_llm(@generated_prompt, files)
      rescue => e
        { success: false, error: e.message, generated_prompt: @generated_prompt }
      end
    end

    private

    def use_sequential_thinking?
      @use_sequential_thinking
    end

    def generate_with_sequential_thinking(processed_content, all_files)
      thinking_service = SequentialThinking.new(model: @model)
      result = thinking_service.think_through_problem(processed_content, all_files)

      if result[:success]
        { success: true, generated_text: result[:final_text], thoughts: result[:thoughts] }
      else
        { success: false, error: result[:error], generated_prompt: @generated_prompt }
      end
    end

    def generate_with_llm(processed_content, all_files)
      llm_service = Llm::Anthropic.new(model: @model)
      result = llm_service.generate(processed_content, all_files)

      if result[:success]
        { success: true, generated_text: result[:text] }
      else
        { success: false, error: result[:error], generation: @generation }
      end
    end
  end
end
