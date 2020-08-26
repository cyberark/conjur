require 'rake'

# Upgrading to FIPs complaint hashing caused us to update the fingerprint
# hash to utilize SHA256 instead of MD5: (https://github.com/cyberark/slosilo/pull/15).
# The following rake task recalculates the fingerprint hashes

# This is a one-way migration
Sequel.migration do
  up do
    Rake::Task['slosilo:recalculate_fingerprints'].execute
  end
end
