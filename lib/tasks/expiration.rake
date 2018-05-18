require 'iso_8601_duration'
require 'master_rotator'
require 'installed_rotators'

namespace :expiration do
  desc "Watch for expired variables and rotate"
  task :watch, [:account] => [:environment] do |t, args|

    #TODO how to do rake args
    MasterRotator.new(rotators: InstalledRotators.new, account: args.account)
      .rotate_every(1)
  end
end
