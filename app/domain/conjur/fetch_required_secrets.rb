require 'command_class'

module Conjur

  FetchRequiredSecrets ||= CommandClass.new(
    dependencies: { resource_class: ::Resource },
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
        raise Errors::Conjur::RequiredResourceMissing, id unless rsc
      end
    end

    def validate_secrets_exist
      secrets.each do |id, secret|
        raise Errors::Conjur::RequiredSecretMissing, id unless secret
      end
    end

    def secret_values
      secrets.transform_values(&:value)
    end

    def resources
      @resources ||= @resource_ids.map { |id| [id, @resource_class[id]] }.to_h
    end

    def secrets
      @secrets ||= resources.map { |id, rsc| [id, rsc.secret] }.to_h
    end
  end
end
