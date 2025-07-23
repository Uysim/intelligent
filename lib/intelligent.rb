# frozen_string_literal: true

require_relative "intelligent/version"
require_relative "intelligent/generation"

module Intelligent
  class Error < StandardError; end

  def self.generate(
    prompt:,
    variables:,
    llm_model:,
    use_sequential_thinking: false,
    files: nil
  )
    generation = Generation.new(prompt, variables, llm_model, use_sequential_thinking, files)
    generation.call
  end
end
