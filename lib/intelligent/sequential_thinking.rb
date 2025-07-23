module Intelligent
  class SequentialThinking
    def initialize(model: "claude-sonnet-4-20250514")
      @model = model
      @anthropic_service = Llm::Anthropic.new(model: model)
    end

    def think_through_problem(problem_description, files = [], max_thoughts = 5)
      thoughts = []
      current_thought = 1
      total_thoughts = max_thoughts

      loop do
        # Build the thinking prompt
        thinking_prompt = build_thinking_prompt(problem_description, thoughts, current_thought, total_thoughts)

        # Generate the next thought with files
        result = @anthropic_service.generate(thinking_prompt, files)

        if result[:success]
          thought_content = result[:text]
          thoughts << {
            number: current_thought,
            content: thought_content,
            timestamp: Time.now
          }

          # Check if we need more thoughts
          needs_more = analyze_thought_completeness(thought_content, current_thought, total_thoughts)

          break if !needs_more || current_thought >= total_thoughts
          current_thought += 1
        else
          return { success: false, error: result[:error] }
        end
      end

      # Generate final answer directly from thinking process
      final_answer = generate_final_answer(problem_description, thoughts, files)

      if final_answer[:success]
        {
          success: true,
          thoughts: thoughts,
          final_text: final_answer[:text]
        }
      else
        { success: false, error: final_answer[:error] }
      end
    end

    private

    def build_thinking_prompt(problem, thoughts, current_thought, total_thoughts)
      previous_thoughts = thoughts.map { |t| "Thought #{t[:number]}: #{t[:content]}" }.join("\n")

      <<~PROMPT
        You are using a sequential thinking process to solve a complex problem.
        Think through this step by step, one thought at a time.

        Problem: #{problem}

        #{previous_thoughts.empty? ? '' : "Previous thoughts:\n#{previous_thoughts}\n"}

        You are currently on Thought #{current_thought} of #{total_thoughts}.

        Instructions:
        1. Provide your next logical thought step
        2. Be specific and actionable
        3. Build upon previous thoughts
        4. If this is your final thought, clearly state your conclusion
        5. If you need more thoughts, indicate what still needs to be addressed

        Thought #{current_thought}:
      PROMPT
    end

    def analyze_thought_completeness(thought_content, current_thought, total_thoughts)
      # Simple heuristic: if the thought mentions conclusion, final answer, or summary
      conclusion_indicators = [ "conclusion", "final answer", "summary", "therefore", "thus", "in conclusion" ]

      has_conclusion = conclusion_indicators.any? { |indicator| thought_content.downcase.include?(indicator) }

      # Continue if no conclusion and we haven't reached max thoughts
      !has_conclusion && current_thought < total_thoughts
    end

    def generate_final_answer(problem_description, thoughts, files)
      thinking_summary = thoughts.map { |t| "Step #{t[:number]}: #{t[:content]}" }.join("\n")

      final_prompt = <<~PROMPT
        Based on your step-by-step thinking process below, provide ONLY the final answer to the original problem. Do not include any thinking process, explanations, or meta-commentary.

        Original Problem: #{problem_description}

        Your Thinking Process:
        #{thinking_summary}

        Instructions:
        1. Provide ONLY the final answer
        2. Do not include phrases like "Based on my analysis" or "Therefore"
        3. Do not explain your reasoning
        4. Give a direct, actionable response
        5. Be concise and to the point

        Final Answer:
      PROMPT

      @anthropic_service.generate(final_prompt, files)
    end
  end
end