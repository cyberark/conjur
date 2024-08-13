require 'anyway/config'
require 'anyway/loaders/base'
require 'net/http'
require 'json'

# Loads properties from Spring Config Server

module Anyway
  module Loaders
    class SpringConfigLoader < Base

      DEFAULT_ENDPOINT = 'http://configuration-manager.configuration-manager.svc.cluster.local:8080'

      def call(config)
        settings = self.class.fetch_configs

        # Update config with the fetched settings
        settings.each do |key, value|
          config[self.class.adjust_key(key)] = value
        end
        config
      end

      def self.fetch_configs
        config_server_url = config_server
        application_name = 'conjur'
        spring_profiles = ENV['TENANT_PROFILES']
        result = {}
        if spring_profiles
          uri = build_uri(config_server_url, application_name, spring_profiles)
          response = Net::HTTP.get(uri, fetch_token)
          config_data = JSON.parse(response)
          result = config_data['propertySources']
                   .reverse # To iterate from last precedence to first
                   .map{|ps| ps['source']}
                   .reduce(:merge)
        end
        result
      rescue => e
        logger.error("Failed to load configuration from Config Server: #{e.message}")
        raise e if defined?(::Rails) && ::Rails.env.cloud?
        {}
      end

      def self.adjust_key(key)
        key.gsub('.', '_').to_sym
      end

      private

      def self.build_uri(config_server_url, application_name, profiles)
        uri = "#{config_server_url}/#{application_name}/#{profiles}"
        uri += "/#{ENV['GITOPS_BRANCH']}" if ENV['GITOPS_BRANCH']
        URI(uri)
      end

      def self.config_server
        if defined?(::Rails) and ::Rails.application.config.respond_to?(:config_server_endpoint)
          ::Rails.application.config.config_server_endpoint
        else
          DEFAULT_ENDPOINT
        end
      end

      def self.logger
        if defined?(::Rails)
          ::Rails.logger
        else
          Logger.new($stderr)
        end
      end

      def self.fetch_token
        file_path_in_pod = "/var/run/secrets/kubernetes.io/serviceaccount/token"
        x_token = "X-token"
        {x_token => File.read(file_path_in_pod).strip}
      rescue Errno::ENOENT => e
        logger.warn("Error reading token from file to fetch properties. #{e.message}")
        {x_token => 'empty'}
      end
    end
  end
end
