# frozen_string_literal: true

module Conjur
  module FeatureFlags
    # Provides feature flagging support
    class Features
      # Instantiates a new Conjur::FeatureFlags::Features object
      #
      # @param logger [Logger] the logger used for output
      # @param environment_settings [Hash] the environment variable has (typically ENV)
      # @param feature_flags [Array<Symbol>] the list of valid feature flags
      #
      # @return [Conjur::FeatureFlags::Features]
      def initialize(logger:, environment_settings:, feature_flags: [])
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
        @logger.debug("Conjur::FeatureFlags::Features#enabled? - feature flag name: '#{feature_name.inspect}'")
        raise InvalidArguement unless feature_name.is_a?(Symbol)

        symbolized_feature_name = feature_name.downcase
        result = @enabled_features.key?(symbolized_feature_name) &&
          @enabled_features[symbolized_feature_name]
        @logger.debug("Conjur::FeatureFlags::Features#enabled? result: '#{result}'")
        result
      end

      private

      # Builds a hash of the feature flags whether they should be toggled on or
      # off. Environment variable flags are set with the following format:
      #   CONJUR_FEATURE_<feature_name>_ENABLED
      #
      # @param features [Array<Symbol>] list of feature flags
      # @param environment [Hash] the environment variables and their values
      #
      # @return [Hash<Symbol>:<Boolean>] hash of feature names and their enabled state (true/false)
      def merge_with_environment_variable_flags(features:, env:)
        features.map do |f|
          enabled = env["CONJUR_FEATURE_#{f.upcase}_ENABLED"].to_s == 'true'
          log_reason_enabled(f) if enabled
          [f, enabled]
        end.to_h
      end

      def log_reason_enabled(feature)
        @logger.debug(
          "Feature '#{feature}' enabled via CONJUR_FEATURE_#{feature.upcase}_ENABLED"
        )
      end
    end

    # Provides an error for when an invalid argement is passed to the `enabled?`
    # method. Only Symbols are currently accepted.
    class InvalidArguement < StandardError
      def message
        'Feature name must be a symbol'
      end
    end
  end
end
