# frozen_string_literal: true
require 'spec_helper'

describe "Ongoing handler" do
  let(:log_output) { StringIO.new }
  let(:logger) { Logger.new(log_output) }
  subject { EdgeLogic::DataHandlers::OngoingHandler.new(logger) }

  context "Input validation" do
    it "edge version" do
      expect(subject.input_validator.call("edge_version", "v1.0.0")).to eq(true)
      expect(subject.input_validator.call("edge_version", "1.0.0")).to eq(true)

      expect(subject.input_validator.call("edge_version", "bad_version")).to eq(false)
    end

    it "edge container type" do
      expect(subject.input_validator.call("edge_container_type", "Podman")).to eq(true)
      expect(subject.input_validator.call("edge_container_type", "podman")).to eq(true)
      expect(subject.input_validator.call("edge_container_type", "Docker")).to eq(true)

      expect(subject.input_validator.call("edge_container_type", "shocker")).to eq(false)
    end

    it "numeric params" do
      expect(subject.input_validator.call("last_synch_time", 456432)).to eq(true)

      expect(subject.input_validator.call("last_synch_time", "Four")).to eq(false)
    end
  end
end

