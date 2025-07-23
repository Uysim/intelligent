# frozen_string_literal: true

RSpec.describe Intelligent::Llm::Base do
  describe "#initialize" do
    it "can be instantiated" do
      expect { described_class.new }.not_to raise_error
    end

    it "uses default provider and model" do
      instance = described_class.new
      expect(instance.provider).to eq("anthropic")
      expect(instance.model).to eq("claude-sonnet-4-20250514")
    end
  end

  describe "#generate" do
    it "raises NotImplementedError" do
      instance = described_class.new
      expect { instance.generate("test") }.to raise_error(NotImplementedError)
    end
  end
end 