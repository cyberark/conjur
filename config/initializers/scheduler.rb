require 'rufus-scheduler'
require_relative '../../app/domain/messages/message_job'

# Do not schedule when Rails is run from a test/spec
return if Rails.env.test?

scheduler = Rufus::Scheduler.singleton(lockfile: ".slosilo-rotation-rufus-scheduler.lock")
interval = Rails.application.config.conjur_config.slosilo_rotation_interval
scheduler_pubsub = Rufus::Scheduler.new
events_to_sns_interval = Rails.application.config.conjur_config.events_to_sns_interval

unless scheduler.down?
  scheduler.every "#{interval}h", first_in: 5.minutes.since do
    system("rake rotate:slosilo")
  end
end

unless scheduler_pubsub.down?
  scheduler_pubsub.every "#{events_to_sns_interval}s", first_in: 5.minutes.since do
    begin
      MessageJob.instance.run
    rescue => e
      Rails.logger.error("Failed to publish events to SNS: #{e.message}")
    end
  end
end
