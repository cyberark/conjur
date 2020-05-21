require 'util/error_code'

namespace :error_code do
  task :next do
    error_code = Error::ConjurCode.new('./app/domain/errors.rb')
    error_code.print_next_available
  end
end
