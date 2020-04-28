require 'rack/default_content_type'

Rails.application.configure do
  config.middleware.use ::Rack::DefaultContentType
end
