# frozen_string_literal: true
require 'aws-sdk-core'

module Aws
  class AppConfigDataClient

    def get_latest_configuration
      app_config = pull_from_app_config
      tenant_name = Rails.application.config.conjur_config.tenant_name
      extract_active_features(app_config, tenant_name)
    end

    private
    def pull_from_app_config
      response = nil
      tenant_env = Rails.application.config.conjur_config.tenant_env
      tenant_region = Rails.application.config.conjur_config.tenant_region

      Aws.config.update(region: tenant_region)

      appconfig_client = Aws::AppConfigData::Client.new
      # It's ok to start a new session every time because at most this call will be made once per minute
      response = appconfig_client.start_configuration_session({
                                                                application_identifier: "#{tenant_env}-feature-flags-conjur",
                                                                environment_identifier: "#{tenant_env}-feature-flags-stable",
                                                                configuration_profile_identifier: "#{tenant_env}-feature-flags-conjur"
                                                              })

      response = appconfig_client.get_latest_configuration({
                                                             configuration_token: response.initial_configuration_token
                                                           })

      response.configuration.read
    rescue => e
      Rails.logger.error("Error pulling app config data: #{e}")
      raise ApplicationController::InternalServerError, "Error pulling app config data" + e.message
    ensure
      response.configuration.close if response&.configuration
    end

    def extract_active_features(json, tenant_name)
      json_data = JSON.parse(json)
      return json_data.select do |key, value|
        if value == 'ALWAYS_ON'
          true
        elsif value == 'ALWAYS_OFF'
          false
        elsif value['ON_ONLY_FOR_SPECIFIC_TENANTS']
          value['ON_ONLY_FOR_SPECIFIC_TENANTS'].include?(tenant_name)
        elsif value['OFF_ONLY_FOR_SPECIFIC_TENANTS']
          value['OFF_ONLY_FOR_SPECIFIC_TENANTS'].exclude?(tenant_name)
        else
          Rails.logger.error("Invalid value for feature flag #{key}: #{value}")
          false # invalid value
        end
      end.keys
    rescue => e
      Rails.logger.error("Error parsing app config data: #{e.message}")
      raise ApplicationController::UnprocessableEntity, "Invalid app config data: #{json} - #{e.message}"
    end

  end
end
