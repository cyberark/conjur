require 'spec_helper'

describe Commands::Policy::ExplainError do
  it "returns a user-friendly error description for `error1`" do
    explain = Commands::Policy::ExplainError.new
    expect(explain.call(parse_error: 'Unexpected scalar')).to eq('Please check the syntax for defining a new node.')
  end
end
