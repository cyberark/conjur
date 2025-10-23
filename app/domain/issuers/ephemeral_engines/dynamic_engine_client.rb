# frozen_string_literal: true

module Issuers
  module EphemeralEngines
    class DynamicEngineClient
      def dynamic_secret(type, method, role_id, issuer_data, variable_data)
        raise NotImplementedError,
              "This method is not implemented because it's an interface"
      end
    end
  end
end
