# frozen_string_literal: true

require 'spec_helper'

describe Tracing do
  let!(:orig_tracing_enabled) { Rails.application.config.conjur_config.tracing_enabled }

  let(:tracer) { double(::OpenTelemetry::Trace::Tracer) }
  
  before do
    @controller = StatusController.new
    
    Rails.application.config.conjur_config.tracing_enabled = true

    allow(Rails.application.config).to receive(:tracer).and_return(tracer)
  end

  after do
    Rails.application.config.conjur_config.tracing_enabled = orig_tracing_enabled
  end
  
  it "performs trace" do
    expect(tracer).to receive(:in_span).with("/").once

    get("index")
  end
end
