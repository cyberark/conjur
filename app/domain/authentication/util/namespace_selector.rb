# frozen_string_literal: true

module Authentication
  module Util
    class NamespaceSelector
      class << self
        def type_to_module(authenticator_type)
          raise("Authenticator type is missing or nil") unless authenticator_type.present?

          mapping[authenticator_type] || authenticator_type.underscore.camelize
        end

        def module_to_type(mod)
          inverted_mapping = mapping.invert
          inverted_mapping[mod] || mod.underscore.dasherize
        end

        private

        def mapping
          {
            'authn' => 'AuthnApiKey'
          }
        end
      end
    end
  end
end
