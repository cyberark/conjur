# frozen_string_literal: true

module AuthenticatorsV2
  class AuthenticatorTypeFactory
    # A hash that maps types to their respective classes
    AUTHENTICATOR_CLASSES = {
      "jwt" => JwtAuthenticatorType,
      "aws" => AwsAuthenticatorType,
      "azure" => AzureAuthenticatorType,
      "gcp" => GcpAuthenticatorType,
      "ldap" => LdapAuthenticatorType,
      "k8s" => K8sAuthenticatorType
    }.freeze

    # Creates an authenticator instance based on the given type
    #
    # @param [String] type - The type of authenticator (e.g., "jwt")
    # @param [Object] authenticator_dict - Object containing authenticator parameters
    #
    # @return [JwtAuthenticatorType] if type is "jwt"
    # @return [AwsAuthenticatorType] if type is "aws"
    # @return [AzureAuthenticatorType] if type is "azure"
    # @return [GcpAuthenticatorType] if type is "gcp"
    # @raise [ApplicationController::UnprocessableEntity] if type is nil or unsupported
    def create_authenticator_type(type, authenticator_dict)
      raise ApplicationController::UnprocessableEntity, "Authenticator type is required" if type.nil?

      authenticator_class = AUTHENTICATOR_CLASSES[type]

      return authenticator_class.new(authenticator_dict) if authenticator_class

      raise ApplicationController::UnprocessableEntity, "'#{type}' authenticators are not supported."
    end
  end
end
