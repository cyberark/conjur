# frozen_string_literal: true

module LoggingConcern
  extend ActiveSupport::Concern
  include Logging

  def log_debug_requested
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("#{request.method} #{request.path}"))
  end

  def log_debug_finished
    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("#{request.method} #{request.path}"))
  end
end
