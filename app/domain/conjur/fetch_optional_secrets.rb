require 'command_class'

module Conjur

  FetchOptionalSecrets ||= CommandClass.new(
    dependencies: { resource_class: ::Resource },
    inputs: [:resource_ids]
  ) do
    def call
      secret_values
    end

    private

    def secret_values
      transformed_secrets = secrets.transform_values do |secret|
        secret ? secret.value : nil
      end
      transformed_secrets
    end 
    
    def resources
      @resource_ids.map { |id| [id, @resource_class[id]] }.to_h
    end
    
    def secrets
      transformed_secrets = resources.transform_values do |resource|
        resource ? resource.secret : nil
      end
      @secrets ||= transformed_secrets
    end
  end
end
