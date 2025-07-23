# frozen_string_literal: true

RSpec.describe Intelligent::Prompt do
  describe "#initialize" do
    it "can be instantiated" do
      expect { described_class.new("test content") }.not_to raise_error
    end

    it "sets the content" do
      prompt = described_class.new("test content")
      expect(prompt.content).to eq("test content")
    end
  end

  describe "#extract_variables" do
    it "extracts variables from content" do
      prompt = described_class.new("Hello {{name}}, how are you {{mood}}?")
      expect(prompt.extract_variables).to eq(["name", "mood"])
    end

    it "returns empty array for content without variables" do
      prompt = described_class.new("Hello world")
      expect(prompt.extract_variables).to eq([])
    end
  end

  describe "#process_content" do
    it "replaces variables with values" do
      prompt = described_class.new("Hello {{name}}!")
      result = prompt.process_content({ "name" => "World" })
      expect(result).to eq("Hello World!")
    end
  end
end 