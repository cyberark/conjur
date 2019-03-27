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

  MissingRequestParam = ::Util::ErrorClass.new(
    "field '{0}' is missing or empty in request body"
  )

  module AuthnOidc

    IdTokenFieldNotFound = ::Util::ErrorClass.new(
      "field '{0}' not found in ID Token"
    )
  end

end
