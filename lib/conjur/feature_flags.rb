# frozen_string_literal: true

module Conjur
  module FeatureFlags
    # Provides feature flagging support
    class Features
      # Instantiates a new Conjur::FeatureFlags::Features object
      #
      # @param logger [Logger] the logger used for output
      # @param environment_settings [Hash] the environment variable has
      #   (typically ENV)
      # @param feature_flags [Array<Symbol>] the list of valid feature flags
      #
      # @return [Conjur::FeatureFlags::Features]
      def initialize(
        logger: Rails.logger,
        environment_settings: ENV,
        feature_flags: {}
      )
        @logger = logger
        @enabled_features = merge_with_environment_variable_flags(
          features: feature_flags,
          env: environment_settings
        )
      end

      # Check to see if a feature flag has been enabled
      #
      # @param feature_name [Symbol] the feature flag we want to check
      #
      # @return [Boolean]
      def enabled?(feature_name)
        @logger.debug(
          "Conjur::FeatureFlags::Features#enabled? " \
          "- feature flag name: '#{feature_name.inspect}'"
        )

        validate(feature_name)
        result = @enabled_features[feature_name]

        @logger.debug(
          "Conjur::FeatureFlags::Features#enabled? result: '#{result}'"
        )

        result
      end

      private

      # Verifies that the feature flag is valid
      #
      # @param feature_name [Symbol] the feature flag we want to check
      #
      # @return [nil]
      def validate(feature_name)
        unless feature_name.is_a?(Symbol)
          raise ArgumentError, 'Feature name must be a symbol'
        end

        return if @enabled_features.key?(feature_name)

        raise InvalidFeatureFlagError, feature_name
      end

      # Builds a hash of the feature flags whether they should be toggled on or
      # off. Environment variable flags are set with the following format:
      #   CONJUR_FEATURE_<feature_name>_ENABLED
      #
      # @param features [Array<Symbol>] list of feature flags
      # @param environment [Hash] the environment variables and their values
      #
      # @return [Hash<Symbol>:<Boolean>] hash of feature names and their enabled
      #   state (true/false)
      def merge_with_environment_variable_flags(features:, env:)
        features.to_h do |feature, default_value|
          env_key = "CONJUR_FEATURE_#{feature.upcase}_ENABLED"

          # Check environment variable for feature flag
          # We only care about specific 'true' or 'false' values
          case env[env_key].to_s.downcase
          when 'true'
            @logger.debug(
              "Feature '#{feature}' enabled via " \
              "environment variable '#{env_key}'"
            )

            next [feature, true]
          when 'false'
            @logger.debug(
              "Feature '#{feature}' disabled via " \
              "environment variable '#{env_key}'"
            )

            next [feature, false]
          end

          # Only log for default state if the flag is enabled by default
          if default_value
            @logger.debug("Feature '#{feature}' enabled by default")
          end

          [feature, default_value]
        end
      end

      # Provides an error for when an invalid flag is passed to the
      # `enabled?` method. The flag must be in the list of valid flags.
      class InvalidFeatureFlagError < StandardError
        def initialize(flag_name)
          super("Feature flag not defined: #{flag_name}")
        end
      end
    end
  end
end
