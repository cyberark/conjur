# frozen_string_literal: true

namespace :expiration do
  desc "Watch for expired variables and rotate"
  task :watch => :environment do
    Rotation::MasterRotator.new(
      avail_rotators: Rotation::InstalledRotators.new
    ).rotate_every(1)
  end
end
