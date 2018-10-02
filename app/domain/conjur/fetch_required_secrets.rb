require 'command_class'
require 'util/error_class'

module Conjur

  # TODO: really, these errors should be inside FetchRequiredSecrets but that
  # will require changing its interface
  #
  RequiredResourceMissing = Util::ErrorClass.new(
    'Missing required resource: {0}'
  )
  RequiredSecretMissing = Util::ErrorClass.new(
    'Missing secret for resource: {0}'
  )

  FetchRequiredSecrets = ::CommandClass.new(
    dependencies: {resource_repo: ::Resource},
    inputs: [:resource_ids]
  ) do

    def call
      validate_resources_exist
      validate_secrets_exist
      secret_values
    end

    private

    def validate_resources_exist
      resources.each do |id, rsc|
        raise RequiredResourceMissing, id unless rsc
      end
    end

    def validate_secrets_exist
      secrets.each do |id, secret|
        raise RequiredSecretMissing, id unless secret
      end
    end

    def secret_values
      secrets.transform_values(&:value)
    end

    def resources
      @resources ||= @resource_ids.map { |id| [id, @resource_repo[id]] }.to_h
    end

    def secrets
      @secrets ||= resources.map { |id, rsc| [id, rsc.secret] }.to_h
    end
  end
end
