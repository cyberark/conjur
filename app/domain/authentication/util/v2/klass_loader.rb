# frozen_string_literal: true

module Authentication
  module Util
    module V2
      # This is a utility to handle detection of Authenticator and Annotation
      # validations. This enables us to optionally add validations for a particular
      # authenticator.
      #
      class KlassLoader
        def initialize(type, namespace_selector: Authentication::Util::NamespaceSelector)
          @classified_type = namespace_selector.type_to_module(type)
        end

        def strategy
          find('Strategy')
        end

        def data_object
          find('DataObjects::Authenticator')
        end

        def authenticator_validation
          find('Validations::AuthenticatorConfiguration')
        end

        private

        def find(name)
          AuthenticatorLoader.authenticator_klasses.find { |klass| klass.name.match?("Authentication::#{@classified_type}::V2::#{name}") }
        end
      end
    end
  end
end
