# frozen_string_literal: true

# turn off Controller logs
ActionController::LogSubscriber.detach_from :action_controller unless ENV['PRINT_CONTROLLERS_LOGS'] == 'true'
# turn off DB logs
SequelRails::Railties::LogSubscriber.detach_from :sequel unless ENV['PRINT_DB_LOGS'] == 'true'
