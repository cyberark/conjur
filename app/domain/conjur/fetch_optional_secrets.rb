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
      secrets.transform_values do |secret|
        secret ? secret.value : nil
      end
    end 
    
    def resources
      @resources ||= @resource_ids.map { |id| [id, @resource_class[id]] }.to_h
    end
    
    def secrets
      @secrets ||= resources.transform_values do |resource|
        resource ? resource.secret : nil
      end
    end
  end
end
