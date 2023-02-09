Rails.application.configure do
  # Create a single instance of the ConjurConfig object for this process that
  # loads configuration on server startup. This prevents config values from
  # being loaded fresh every time a ConjurConfig object is instantiated, which
  # could lead to inconsistent behavior.
  config.conjur_config = Conjur::ConjurConfig.new(
    logger: Rails.logger
  )
end
