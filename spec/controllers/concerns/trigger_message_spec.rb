# frozen_string_literal: true
require 'spec_helper'


RSpec.describe TriggerMessage, type: :controller do
  controller(ApplicationController) do
    include TriggerMessage
  end



  describe "#trigger_message_job" do
    context "when ENABLE_PUBSUB is true" do
      before { ENV['ENABLE_PUBSUB'] = 'true' }

      it "executes the MessageJob in a new thread" do
        expect(MessageJob.instance).to receive(:run)
        subject.trigger_message_job
      end

      it "raises a StandardError if one is raised" do
        allow(MessageJob.instance).to receive(:run).and_raise(StandardError, "test error")
        subject.trigger_message_job
      end
    end

    context "when ENABLE_PUBSUB is not true" do
      before { ENV['ENABLE_PUBSUB'] = 'false' }

      it "does not execute the MessageJob" do
        expect(MessageJob.instance).not_to receive(:run)
        subject.trigger_message_job
      end
    end
  end
end