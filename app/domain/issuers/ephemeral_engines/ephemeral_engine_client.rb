# frozen_string_literal: true

module EphemeralEngineClient
  def get_ephemeral_secret(type, method, role_id, issuer_data, variable_data)
    raise NotImplementedError, "This method is not implemented because it's an interface"
  end
end
