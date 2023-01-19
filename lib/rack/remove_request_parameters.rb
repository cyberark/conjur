# frozen_string_literal: true

require 'forwardable'

module Rack
  # RemoveRequestParameters is responsible for setting the
  # `action_dispatch.request.request_parameters` Rack header to an empty hash.
  # This prevents Rack or Rails from attempting to parse the request body for
  # available parameters.
  #
  # Because the request body will often contain sensitive information, we don't
  # want the body, or any part of it, to a be logged by Rack or Rails
  # middleware.
  #
  # Anytime information is passed through the Request body, it must be
  # explicitly handled in the Controller.
  class RemoveRequestParameters
    def initialize(app)
      @app = app
    end

    def call(env)
      req = ActionDispatch::Request.new(env)
      req.set_header("action_dispatch.request.request_parameters", {})

      @app.call(env)
    end
  end
end
