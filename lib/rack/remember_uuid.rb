module Rack
  # Middleware to store request ID in a thread variable
  class RememberUuid
    def initialize app
      @app = app
    end

    def call env
      Thread.current[:request_id] = env["action_dispatch.request_id"]
      @app.call env
    end
  end
end
