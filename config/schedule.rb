require File.expand_path('../config/environment', __dir__)


every Rails.application.config.conjur_config.slosilo_rotation_interval.minutes do
  rake 'rotate:slosilo'
end