require 'rack/remove_request_parameters'

Rails.application.configure do
  # Prevent Rails or Rack from attempting to parse the Request body
  # for parameters. See the comment on ::Rack::EmptyRequestParameters for
  # additional details.
  config.middleware.insert_before(0, ::Rack::RemoveRequestParameters)
end
