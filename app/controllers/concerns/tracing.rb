# frozen_string_literal: true

# A concern that adds OpenTelemetry tracing to controller methods.
module Tracing
  extend ActiveSupport::Concern
  
  included do
    around_action :trace
  end
  
  # rubocop:disable Style/ExplicitBlockArgument
  def trace
    return unless Tracing.tracing_enabled?

    Rails.application.config.tracer.in_span(request.env['PATH_INFO']) do
      yield
    end
  end
  # rubocop:enable Style/ExplicitBlockArgument

  def self.tracing_enabled?
    Rails.application.config.conjur_config.tracing_enabled
  end
end
