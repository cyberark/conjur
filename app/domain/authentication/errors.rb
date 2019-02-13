# frozen_string_literal: true

require 'util/error_class'

module Authentication

  AuthenticatorNotFound = ::Util::ErrorClass.new(
    "'{0}' wasn't in the available authenticators"
  )

  InvalidCredentials = ::Util::ErrorClass.new(
    "Invalid credentials"
  )

  InvalidOrigin = ::Util::ErrorClass.new(
    "Invalid origin"
  )

end
