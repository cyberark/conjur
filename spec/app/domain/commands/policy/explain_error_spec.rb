require 'spec_helper'

class MockException < StandardError
  attr_accessor 'detail_message'
end

interpolated_messages = {
  "Unexpected alias «my-weird-alias»": "",
  "Unrecognized data type '!badtag'": 
    "The tag must be one of the following: !delete, !deny, !grant, !group, !host, " \
    "!host-factory, !layer, !permit, !policy, !revoke, !user, !variable, !webservice",
  "No such attribute 'who' on type Thingamajig": "",
  "Duplicate attribute: bing": "",
  "Attribute 'foo' can't be a mapping": "",
  "Expecting 1 or 2 arguments, got 17": "",
  "Duplicate anchor PIRATE": "",
  "Expecting @ for kind, got %%%": "",
  "Expected a date for field 'created', got 'Figs'": "",
  "Invalid IP address or CIDR range '255.1.0.0/8': Value has bits set to right of mask. Did you mean '255.1.0.0'?": "",
  "Invalid IP address or CIDR range '192.168.0.0.0.0.1'": 
    "Make sure your address or range is in the correct format " \
    "(e.g. 192.168.1.0 or 192.168.1.0/16)",
  "YAML field color already defined on sky as blue": "",
  "Thingy has a blank id": "Each resource must be identified using the 'id' field",
  "Invalid relative reference: mom": "",
  "Dependency cycle encountered between bing and bong": "Try redefining one or both.",
  "BOOP is declared more than once": "",
}

describe Commands::Policy::ExplainError do
  context "ExplainError returns user-friendly advice" do

    it "for a constant message" do
      explain = Commands::Policy::ExplainError.new
      error = MockException.new('Mock Error')
      error.detail_message = "Unexpected scalar"
      advice = 'Please check the syntax for defining a new node.'
      expect(explain.call(error)).to eq(advice)
    end

    it "for all interpolated messages" do
      interpolated_messages.each do |msg, advice|
        explain = Commands::Policy::ExplainError.new
        error = MockException.new('Mock Error')
        error.detail_message = msg.to_s
        expect(explain.call(error)).to eq(advice)
      end
    end

    it "returns a default advice string for an unknown error" do
      explain = Commands::Policy::ExplainError.new
      error = MockException.new('Mock Error')
      error.detail_message = 'Unknown error! This is a completely unknown error that never happens.'
      advice = Commands::Policy::DEFAULT_HELP_MSG
      expect(explain.call(error)).to eq(advice)
    end

  end
end
