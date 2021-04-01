# frozen_string_literal: true

require 'spec_helper'

include Conjur::PolicyParser

describe Resolver do
  let(:fixture) { YAML.safe_load(File.read(filename), filename) }
  let(:account) { fixture['account'] || "the-account" }
  let(:ownerid) { fixture['ownerid'] || "rspec:user:default-owner" }
  let(:policy) { Conjur::PolicyParser::YAML::Loader.load(fixture['policy']) }
  let(:resolve) do
    Resolver.resolve(policy, account, ownerid)
  end
  before do
    allow(Conjur).to receive(:configuration).and_return(double(:configuration, account: account))
  end
  subject { resolve.to_yaml }
  
  shared_examples_for "verify resolver" do
    it "matches expected YAML" do
      expected = sorted_yaml(fixture['expectation']) 
      actual = sorted_yaml(subject)
      expect(actual).to eq(expected)
    end
  end

  shared_examples_for "verify error" do
    it "raises the expected error" do
      expect { subject }.to raise_error(fixture['error'])
    end
  end
    
  fixtures_dir = File.expand_path("resolver-fixtures", File.dirname(__FILE__))
  Dir.chdir(fixtures_dir) do
    files = if env = ENV['POLICY_FIXTURES']
      env.split(',')
    else
      Dir['*.yml']
    end

    files.each do |file_example_name|
      describe file_example_name do
        let(:filename) { File.expand_path(file_example_name, fixtures_dir) }
        if file_example_name =~ /-error.yml/
          it_should_behave_like "verify error"
        else
          it_should_behave_like "verify resolver"
        end
      end
    end
  end
end

describe Conjur::PolicyParser::PolicyNamespaceResolver do
  it "prepends namespace to resource ids" do
    record = Types::Resource.new('test-kind', 'test-id')
    resolver.resolve_record(record, nil)
    expect(record.id).to eq('namespace/test-id')
  end

  it "appends namespace to user ids" do
    record = Types::User.new('test-id')
    resolver.resolve_record(record, nil)
    expect(record.id).to eq('test-id@namespace')
  end

  it "leaves absolute ids intact" do
    record = Types::User.new('/test-id')
    resolver.resolve_record(record, nil)
    expect(record.id).to eq('/test-id')
  end

  subject(:resolver) do
    described_class.new('account', 'account:user:owner').tap do |r|
      allow(r).to receive_messages(namespace: 'namespace')
    end
  end
  Types = Conjur::PolicyParser::Types
end
