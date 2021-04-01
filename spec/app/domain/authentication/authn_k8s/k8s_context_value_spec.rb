# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnK8s::K8sContextValue) do
  let(:file_contents) { "MockFileContents" }
  let(:good_file) { double("MockExistentFile") }
  let(:bad_file) { double("MockNonexistentFile") }

  let(:good_resource_id) { "MockSecretIdGood" }
  let(:bad_resource_id) { "MockSecretIdBad" }

  let(:webservice) { double("MockWebservice") }
  let(:secret) { double("MockSecret", value: "MockSecret") }
  let(:resource) { double("MockResource", secret: secret) }

  before(:each) do
    allow(File).to receive(:exist?)
      .with(good_file)
      .and_return(true)

    allow(File).to receive(:exist?)
      .with(bad_file)
      .and_return(false)

    allow(File).to receive(:read)
      .with(good_file)
      .and_return(file_contents)

    allow(webservice).to receive(:variable)
      .with(good_resource_id)
      .and_return(resource)

    allow(webservice).to receive(:variable)
      .with(bad_resource_id)
      .and_return(nil)
  end

  subject { Authentication::AuthnK8s::K8sContextValue }

  describe "get" do
    it "returns the value of a file if it exists" do
      expect(subject.get(webservice, good_file, good_resource_id)).to eq(file_contents)
    end

    it "returns the value of a variable if the file does not exist" do
      expect(subject.get(webservice, bad_file, good_resource_id)).to eq(secret.value)
    end

    it "returns nil when neither exist" do
      expect(subject.get(webservice, bad_file, bad_resource_id)).to be_nil
    end

    it "returns nil when file doesnt exist and variable does but webservice is nil" do
      expect(subject.get(nil, bad_file, good_resource_id)).to be_nil
    end
  end
end
