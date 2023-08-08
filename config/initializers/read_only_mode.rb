# frozen_string_literal: true

Rails.application.configure do
    # Determines whether or not writable API endpoints are enabled.
    #
    # The `read_only` arguement is a boolean. By default, `read_only` is "Off".
    # This means that any of the writable API endpoints will function as intended.
    #
    # A writable API endpoint is one whose controller method is decorated with the
    # `@read_safe` decorator. When `read_only` is "On", such endpoints will return
    # an HTTP 405 Method Not Allowed response code.
    #
    config.read_only = false
  end
  