# frozen_string_literal: true
require 'spec_helper'

describe ExtractEdgeResources do
  let(:account) { "rspec" }
  let(:max_edge_allowed_param) { account + ":variable:edge/edge-configuration/max-edge-allowed" }

  # Test controller class
  class Controller
    include ExtractEdgeResources
  end

  subject(:controller) { Controller.new }

  context "when resource cannot be found" do
    it "max edge allowed not found" do
      allow(Resource).to receive(:[]).with(resource_id: max_edge_allowed_param).and_return(nil)
      expect { subject.extract_max_edge_value(account) }.to raise_error(Errors::Edge::MaxEdgeAllowedNotFound)
    end

    it "max edge allowed is empty" do
      resource = double(Resource).tap do |r|
        allow(r).to receive(:secret).and_return(nil)
      end
      allow(Resource).to receive(:[]).with(resource_id: max_edge_allowed_param).and_return(resource)
      expect { subject.extract_max_edge_value(account) }.to raise_error(Errors::Edge::MaxEdgeAllowedNotFound)
    end
  end

  context "when resource can be found" do
    let(:secret) { double(Secret).tap { |s| allow(s).to receive(:value).and_return("1") } }
    let(:resource) { double(Resource).tap { |r| allow(r).to receive(:secret).and_return(secret) } }
    it "max edge allowed is not empty" do
      allow(Resource).to receive(:[]).with(resource_id: max_edge_allowed_param).and_return(resource)
      expect(subject.extract_max_edge_value(account)).to eq("1")
    end
  end
end
