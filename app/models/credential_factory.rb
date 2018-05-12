module CredentialFactory
  class << self
    def values factory_resource
      provider_annotation = factory_resource.credential_factory_provider
      raise ArgumentError, %Q(Annotation "credential-factory/provider" not found on #{factory_resource.id.inspect}) unless provider_annotation
      require "credential_factory/#{provider_annotation.value.underscore}"
      factory_class = self.const_get(provider_annotation.value.downcase.camelize)

      annotations = factory_resource.annotations.select do |annotation|
        annotation.name =~ /^credential-factory\// && annotation.name != "credential-factory/provider"
      end.inject({}) do |memo, annotation|
        memo[annotation.name] = annotation.value
        memo
      end

      dependent_variable_ids = factory_class.dependent_variable_ids(annotations)

      dependent_variables = dependent_variable_ids.map do |id|
        tokens = id.split(":")
        if tokens.length == 1
          id = [ factory_resource.account, "variable", id ].join(":")
        end

        Resource[id].tap do |variable|
          unless variable
            Rails.logger.info "Variable #{id.inspect} required by #{factory_resource.resource_id.inspect} does not exist"
            raise Exceptions::RecordNotFound, id
          end
        end
      end
      dependent_secrets = dependent_variables.inject({}) do |memo, variable|
        # Don't reveal that a variable exists if the credential factory doesn't have permission to execute it.
        unless factory_resource.role.allowed_to?('execute', variable)
          msg = "#{factory_resource.resource_id.inspect} does not have 'execute' privilege on #{variable.resource_id.inspect}"
          Rails.logger.info msg
          raise Exceptions::Forbidden, "#{factory_resource.resource_id.inspect} does not have 'execute' privilege on #{variable.resource_id.inspect}"
        end
        secret = variable.secrets.last
        unless secret
          raise Exceptions::RecordNotFound.new(variable.resource_id, message: "#{variable.resource_id.inspect} does not contain a secret value")
        end
        memo[variable.identifier.split('/').last.to_sym] = secret.value
        memo
      end

      factory_class.new(factory_resource, dependent_secrets).values
    end
  end
end
