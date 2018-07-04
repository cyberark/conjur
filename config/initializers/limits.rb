# frozen_string_literal: true

# Max number of secrets versions that will be retained.
def secrets_version_limit
  ( ENV['SECRETS_VERSION_LIMIT'] || 20 ).to_i
end

# Max size of policies that can be loaded (or data sent to POST endpoints in
# general.)
# This sets the default size of a Rack::Utils::KeySpaceConstrainedParam, which
# is the type of the body of a policy load API request.
# http://www.rubydoc.info/gems/rack/1.6.2/Rack/Utils/KeySpaceConstrainedParams

Rack::Utils.key_space_limit = 1048576 * 10 # 10 MiB
