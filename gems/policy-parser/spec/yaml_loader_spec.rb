require 'spec_helper'
require 'conjur/policy/yaml/loader'

describe Conjur::PolicyParser::YAML::Loader do
  shared_examples_for "round-trip dsl" do |example|
    let(:filename) { "spec/round-trip/yaml/#{example}.yml" }
    it "#{example}.yml" do
      expected = sorted_yaml File.read("spec/round-trip/yaml/#{example}.expected.yml")
      actual = sorted_yaml Conjur::PolicyParser::YAML::Loader.load_file(filename).to_yaml
      expect(actual).to eq(expected)
    end
  end

  shared_examples_for "error message" do |example|
    let(:filename) { "spec/errors/yaml/#{example}.yml" }
    it "#{example}.yml" do
      lines = File.read(filename).split("\n")
      location, message = lines[0..1].map{|l| l.match(/^#\s+(.*)/)[1]}
      line, column = location.split(',').map(&:strip)
      error_message = "Error at line #{line}, column #{column} in #{filename} : #{message}"
      expect { Conjur::PolicyParser::YAML::Loader.load_file(filename).to_yaml }.to raise_error(Conjur::PolicyParser::Invalid)
      begin
        Conjur::PolicyParser::YAML::Loader.load_file(filename).to_yaml
      rescue Conjur::PolicyParser::Invalid
        expect($!.message).to eq(error_message)
      end
    end
  end
  
  it_should_behave_like 'round-trip dsl', 'empty'
  it_should_behave_like 'round-trip dsl', 'sequence'
  it_should_behave_like 'round-trip dsl', 'record'
  it_should_behave_like 'round-trip dsl', 'members'
  it_should_behave_like 'round-trip dsl', 'permit'
  it_should_behave_like 'round-trip dsl', 'deny'
  it_should_behave_like 'round-trip dsl', 'revoke'
  it_should_behave_like 'round-trip dsl', 'delete'
  it_should_behave_like 'round-trip dsl', 'permissions'
  it_should_behave_like 'round-trip dsl', 'jenkins-policy'
  it_should_behave_like 'round-trip dsl', 'layer-members'
  it_should_behave_like 'round-trip dsl', 'all-types-all-fields'
  it_should_behave_like 'round-trip dsl', 'org'
  it_should_behave_like 'round-trip dsl', 'include'
  it_should_behave_like 'round-trip dsl', 'policy-empty-body'
  it_should_behave_like 'round-trip dsl', 'restricted_to'

  it_should_behave_like 'error message', 'unrecognized-type'
  it_should_behave_like 'error message', 'incorrect-type-for-field-1'
  it_should_behave_like 'error message', 'incorrect-type-for-field-2'
  it_should_behave_like 'error message', 'incorrect-type-for-array-field'
  it_should_behave_like 'error message', 'no-such-attribute'
  it_should_behave_like 'error message', 'invalid-cidr'
  it_should_behave_like 'error message', 'invalid-cidr-2'
  it_should_behave_like 'error message', 'invalid-cidr-3'
  it_should_behave_like 'error message', 'invalid-cidr-in-array'
  it_should_behave_like 'error message', 'multiple-invalid-cidr-in-array'
end
