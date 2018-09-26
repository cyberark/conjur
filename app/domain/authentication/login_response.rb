# frozen_string_literal: true

require 'dry-struct'
require 'types'

module Authentication  
  # Response from an authenticator login method
  class LoginResponse < ::Dry::Struct
    # If successful, the role id of the logged in Role
    attribute :role_id,             ::Types::NonEmptyString.optional

    # If successful, the key that should be return to the client (e.g.
    # the Conjur API key for standard authentication)
    attribute :authentication_key,  ::Types::NonEmptyString.optional
  end
end
