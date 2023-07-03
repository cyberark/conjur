require 'rufus-scheduler'

# Do not schedule when Rails is run from a test/spec
return if Rails.env.test?

scheduler = Rufus::Scheduler.singleton(lockfile: ".slosilo-rotation-rufus-scheduler.lock")
interval = Rails.application.config.conjur_config.slosilo_rotation_interval

unless scheduler.down?
  # Schedule task one second after startup and every interval
  scheduler.every "#{interval}h", first_in: 1.second.since do
    system("rake rotate:slosilo")
  end
end
