# frozen_string_literal: true

# Max number of secrets versions that will be retained.
def secrets_version_limit
  ( ENV['SECRETS_VERSION_LIMIT'] || 20 ).to_i
end

def policies_version_limit
  ( ENV['POLICIES_VERSION_LIMIT'] || 20 ).to_i
end

