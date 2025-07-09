# spec/controllers/concerns/logging_concern_spec.rb
require 'spec_helper'

RSpec.describe(LoggingConcern, type: :controller) do
  controller(ApplicationController) do
    include LoggingConcern

    def test_action
      log_debug_requested
      log_debug_finished
      head(:ok)
    end
  end

  let(:logger) { instance_double(Logger, debug?: true, debug: nil) }

  before do
    allow(controller).to receive(:logger).and_return(logger)
    routes.draw { get 'test_action' => 'anonymous#test_action' }
  end

  describe '#log_debug_requested' do
    it 'logs the request method and path at the beginning' do
      expect(logger).to receive(:debug).with(instance_of(LogMessages::Endpoints::EndpointRequested))
      get :test_action
    end
  end

  describe '#log_debug_finished' do
    it 'logs the request method and path as finished' do
      expect(logger).to receive(:debug).with(instance_of(LogMessages::Endpoints::EndpointFinishedSuccessfully))
      get :test_action
    end
  end
end
