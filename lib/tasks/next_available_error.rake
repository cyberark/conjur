require 'util/error_code'

# error_code:next is used to find the next available error or log code ID for
# Conjur standard logging.
namespace :error_code do
  task :next do
    error_code = Error::ConjurCode.new(
      './app/domain/errors.rb',
      './app/domain/logs.rb'
    )
    error_code.print_next_available
  end
end
