# frozen_string_literal: true

require 'dry-struct'

module CA
  # Represents a user or host's request for a signed certificate
  class Webservice < Dry::Struct
    class << self
      def load(account, service_id)
        identifier_fn = Sequel.function(:identifier, :resource_id)
        kind_fn = Sequel.function(:kind, :resource_id)
        account_fn = Sequel.function(:account, :resource_id)

        resource = Resource
          .where(
            identifier_fn => "conjur/ca/#{service_id}", 
            kind_fn => 'webservice',
            account_fn => account
          )
          .first
        
        Webservice.new(resource: resource)
      end
    end

    attribute :resource, Types.Definition(Resource)

    def max_ttl
      service_max_ttl = resource.annotation('ca/max-ttl')
      raise ArgumentError, "The max TTL (ca/max-ttl) for '#{service_id}' is missing." unless service_max_ttl.present?

      ISO8601::Duration.new(service_max_ttl).to_seconds
    end

    def service_id
      # CA services have ids like 'conjur/ca/<service_id>'
      resource.identifier.split('/')[2]
    end

    def exists?
      resource.present?
    end

    def can_sign?(role)
      role.allowed_to?('sign', resource)
    end

    def variable_annotation(name)
      variable(raw_annotation(name))
    end

    def raw_annotation(name)
      resource.annotation(name)
    end

    private

    def variable(id)
      ::CA::Variable.new(resource: Resource[variable_id(id)]).value if id
    end

    def variable_id(id)
      [resource.account, 'variable', id].join(':')
    end
  end
end
