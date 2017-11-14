# Max number of secrets versions that will be retained.
def secrets_version_limit
  ( ENV['SECRETS_VERSION_LIMIT'] || 20 ).to_i
end

# Max size of policies that can be loaded (or data sent to POST endpoints in
# general)
Rack::Utils.key_space_limit = 1048576 * 10 # 10 MiB
