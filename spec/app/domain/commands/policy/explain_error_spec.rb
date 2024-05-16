require 'spec_helper'

class MockException < Exception
  attr_accessor 'detail_message'
end

describe Commands::Policy::ExplainError do
  it "returns a user-friendly error description for a constant message" do
    explain = Commands::Policy::ExplainError.new
    error = MockException.new('Mock Error')
    error.detail_message = "Unexpected scalar"
    advice = 'Please check the syntax for defining a new node.'
    expect(explain.call(error)).to eq(advice)
  end
end

describe Commands::Policy::ExplainError do
  it "returns a user-friendly error description for an interpolated message" do
    explain = Commands::Policy::ExplainError.new
    error = MockException.new('Mock Error')
    error.detail_message = 'Dependency cycle encountered between ThingOne and ThingTwo.'
    advice = 'Try redefining one or both.'
    expect(explain.call(error)).to eq(advice)
  end
end

describe Commands::Policy::ExplainError do
  it "returns a default error description for an unknown error" do
    explain = Commands::Policy::ExplainError.new
    error = MockException.new('Mock Error')
    error.detail_message = 'Unknown error! This is a completely unknown error that never happens.'
    advice = Commands::Policy::DEFAULT_HELP_MSG
    expect(explain.call(error)).to eq(advice)
  end
end
