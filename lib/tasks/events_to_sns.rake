# This rake task is scheduled once in 30 seconds.
# It fetches events from the database and publishes them to the SNS topic and deletes them from the database.
require_relative '../../app/domain/messages/message_job'

desc "publish events to SNS"
namespace :events_to_sns do
  task :publish => :environment do
    begin
      MessageJob.instance.run
    rescue => e
      Rails.logger.error("Failed to publish events to SNS: #{e.message}")
    end
  end
end