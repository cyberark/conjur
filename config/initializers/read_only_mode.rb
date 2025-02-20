# frozen_string_literal: true

# Put Conjur into "read-only" mode
Rails.application.configure do
  config.read_only = true
end
