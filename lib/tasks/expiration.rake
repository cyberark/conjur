require 'iso_8601_duration'

namespace :expiration do
  desc "Watch for expired variables and rotate"
  task :watch => :environment do

    #TODO: perhaps use clockwork / similar rather than a sleep loop
    while true
      Secret.freshly_expired.each do |secret|
        puts "Secret #{secret[:resource_id]} expired!  Resetting it..."
        Secret.create({
          resource_id: secret[:resource_id],
          expires_at: ISO8601Duration.new(secret[:ttl]).from_now,
          value: SecureRandom.hex(5),
        })
      end
      sleep(1)

    end
  end
end
