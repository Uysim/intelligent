module Intelligent
  class Prompt
    attr_reader :content

    def initialize(content)
      @content = content
    end


    def extract_variables
      @content.scan(/\{\{(\w+)\}\}/).flatten.uniq
    end

    def process_content(input_variables = {})
      processed_content = content.dup
      input_variables.each do |key, value|
        processed_content.gsub!("{{#{key}}}", value.to_s)
      end
      processed_content
    end

    def validate_variables!(input_variables)
      missing_vars = extract_variables - input_variables.keys
      if missing_vars.any?
        raise "Missing required variables: #{missing_vars.join(', ')}"
      end
    end
  end
end