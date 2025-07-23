# Intelligent

A Ruby gem that provides intelligent text generation using LLMs (Large Language Models) with support for prompt templating, file attachments, and sequential thinking.

## Features

- **Prompt Templating**: Use `{{variable}}` syntax to create dynamic prompts
- **Multiple LLM Models**: Support for various Claude models (Sonnet, Opus, Haiku)
- **File Attachments**: Attach images, text files, and PDFs to your prompts
- **Sequential Thinking**: Enable step-by-step reasoning for complex problems
- **Error Handling**: Robust error handling with detailed feedback
- **Variable Validation**: Automatic validation of required prompt variables

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'intelligent'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install intelligent
```

## Configuration

Set your Anthropic API key as an environment variable:

```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

## Usage

### Basic Usage

```ruby
require 'intelligent'

# Simple text generation
result = Intelligent.generate(
  prompt: "Write a short story about {{character}} who {{action}}",
  variables: {
    character: "a brave knight",
    action: "discovers a magical sword"
  },
  llm_model: "claude-sonnet-4-20250514"
)

if result[:success]
  puts result[:generated_text]
else
  puts "Error: #{result[:error]}"
end
```

### With File Attachments

```ruby
# Attach files to your prompt
files = [
  File.open("document.pdf"),
  File.open("image.png")
]

result = Intelligent.generate(
  prompt: "Analyze this {{document_type}} and summarize the key points",
  variables: { document_type: "financial report" },
  llm_model: "claude-opus-4-20250514",
  files: files
)
```

### Sequential Thinking

For complex problems that require step-by-step reasoning:

```ruby
result = Intelligent.generate(
  prompt: "Solve this math problem: {{problem}}",
  variables: { problem: "If a train travels 120 km in 2 hours, what is its speed?" },
  llm_model: "claude-sonnet-4-20250514",
  use_sequential_thinking: true
)

if result[:success]
  puts "Final Answer: #{result[:generated_text]}"
  puts "\nThinking Process:"
  result[:thoughts].each do |thought|
    puts "Step #{thought[:number]}: #{thought[:content]}"
  end
end
```

### Available Models

```ruby
# Get available models
models = Intelligent::Llm::Anthropic.available_models
models.each do |model_id, description|
  puts "#{model_id}: #{description}"
end

# Available models:
# "claude-sonnet-4-20250514": "Claude Sonnet 4 (Recommended)"
# "claude-opus-4-20250514": "Claude Opus 4 (Most Capable)"
# "claude-3-7-sonnet-20250219": "Claude Sonnet 3.7 (Fast)"
# "claude-3-5-haiku-20241022": "Claude Haiku 3.5 (Fastest)"
```

### Advanced Prompt Templates

```ruby
# Complex prompt with multiple variables
prompt = <<~PROMPT
  You are a {{role}} expert. 
  
  Task: {{task}}
  
  Context: {{context}}
  
  Requirements:
  - {{requirement1}}
  - {{requirement2}}
  
  Please provide a detailed response.
PROMPT

variables = {
  role: "software architect",
  task: "design a microservices architecture",
  context: "e-commerce platform with 10,000 daily users",
  requirement1: "high availability",
  requirement2: "scalable design"
}

result = Intelligent.generate(
  prompt: prompt,
  variables: variables,
  llm_model: "claude-opus-4-20250514"
)
```

## API Reference

### `Intelligent.generate`

Main method for generating text with LLMs.

**Parameters:**
- `prompt` (String): The prompt template with optional `{{variable}}` placeholders
- `variables` (Hash): Variables to substitute in the prompt template
- `llm_model` (String): The LLM model to use (see available models above)
- `use_sequential_thinking` (Boolean, optional): Enable step-by-step reasoning (default: false)
- `files` (Array, optional): Array of File objects to attach to the prompt

**Returns:**
- Hash with the following structure:
  - `success` (Boolean): Whether the generation was successful
  - `generated_text` (String): The generated text (if successful)
  - `thoughts` (Array): Array of thinking steps (if sequential thinking was used)
  - `error` (String): Error message (if failed)

## Supported File Types

- **Images**: JPG, JPEG, PNG, GIF, WebP
- **Text Files**: TXT, MD, RB, PY, JS, HTML, CSS, JSON, XML, YAML, YML
- **Documents**: PDF

## Error Handling

The gem provides comprehensive error handling:

```ruby
result = Intelligent.generate(
  prompt: "Hello {{name}}",
  variables: {}, # Missing required variable
  llm_model: "claude-sonnet-4-20250514"
)

if !result[:success]
  puts "Error: #{result[:error]}"
  # Output: Error: Missing required variables: name
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/uysim/intelligent. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/uysim/intelligent/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Intelligent project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/uysim/intelligent/blob/main/CODE_OF_CONDUCT.md).
