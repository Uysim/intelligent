# frozen_string_literal: true

RSpec.describe Intelligent do
  it "has a version number" do
    expect(Intelligent::VERSION).not_to be nil
  end

  it "can be required without error" do
    expect { require "intelligent" }.not_to raise_error
  end
end 