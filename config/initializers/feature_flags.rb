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

  # Hash of feature flags. The hash key is the feature flag name, the value is
  # the status if no flag is given (its default state).
  # ex. { telemetry: true }
  feature_flags = {
    # When enabled, policy load extensions cause the policy orchestration
    # to emit lifecycle event callbacks (e.g. before_insert, after_load_policy)
    # during policy load.
    policy_load_extensions: false,

    # If enabled, the Roles API will emit callbacks to extensions for
    # before/after events when role memberships are added or removed
    # through the REST API.
    roles_api_extensions: false,
  }.freeze

  config.feature_flags = Conjur::FeatureFlags::Features.new(
    logger: Rails.logger,
    environment_settings: ENV,
    feature_flags: feature_flags
  )
end
