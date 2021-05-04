Rails.application.configure do
  # Loads Feature Flag configuration.
  #
  # The `feature_flags` arguement is an array of valid feature flags (as Ruby
  # Symbols) used in Conjur to limit or prevent access to a new feature.
  #
  # By default, all feature flags are toggled "Off".  A feature can be enabled
  # by setting an environment variable of the following form:
  #
  # CONJUR_FEATURE_<feature_name>_ENABLED=true
  #
  # <feature_name> must match the flag provide in the `feature_flags` arguement.
  #
  # The feature flag is available for using the following form:
  #
  # Rails.configuration.feature_flags.enabled?(:feature_name)

  feature_flags = [] # Array of feature flags as Ruby symbols, ex. [:telemetry]

  config.feature_flags = Conjur::FeatureFlags::Features.new(
    logger: Rails.logger,
    environment_settings: ENV,
    feature_flags: feature_flags
  )
end
