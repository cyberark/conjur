# frozen_string_literal: true
require 'action_view/log_subscriber'

unless ENV['PRINT_CONTROLLERS_LOGS']  == 'true'
  # turn off Controller logs
  ActionController::LogSubscriber.detach_from :action_controller
  ActionView::LogSubscriber.detach_from :action_view # Removes 'Rendered' messages

  #This code makes Rails::Rack::Logger to not emit logs. In particular it suppresses the log of Started GET/POST ... for every request
  # It is commented out because it doesn't work well, since Logger.new('/dev/null') does not support tags, thereby omits out tags (see `log_tags`)
  #
  # module SuppressRackLogging
  #   def logger
  #     @null_logger ||= Logger.new('/dev/null')
  #   end
  # end
  # Rails::Rack::Logger.prepend(SuppressRackLogging)
end

# turn off DB logs
SequelRails::Railties::LogSubscriber.detach_from :sequel unless ENV['PRINT_DB_LOGS'] == 'true'
