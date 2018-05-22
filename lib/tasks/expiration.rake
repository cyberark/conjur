require 'iso_8601_duration'
# require_relative '../../app/domain/rotation/master_rotator'
# require_relative '../../app/domain/rotation/installed_rotators'

namespace :expiration do
  desc "Watch for expired variables and rotate"
  task :watch => :environment do
    Rotation::MasterRotator.new(
      rotators: Rotation::InstalledRotators.new
    ).rotate_every(1)
  end
end
