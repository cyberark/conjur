# frozen_string_literal: true

module AuthenticatorsV2
  class AuthenticatorTypeFactory
    def initialize
      @success = ::SuccessResponse
      @failure = ::FailureResponse
    end

    # A hash that maps types to their respective classes
    AUTHENTICATOR_CLASSES = {
      "authn-jwt" => JwtAuthenticatorType,
      "authn-iam" => AwsAuthenticatorType,
      "authn-azure" => AzureAuthenticatorType,
      "authn-gcp" => GcpAuthenticatorType,
      "authn-oidc" => OidcAuthenticatorType,
      "authn-ldap" => LdapAuthenticatorType,
      "authn-k8s" => K8sAuthenticatorType
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
    def create_authenticator_type(authenticator_dict)
      type = authenticator_dict[:type]
      if type.nil?
        return @failure.new(
          "Authenticator type is required",
          status: :unprocessable_entity,
          exception: ApplicationController::UnprocessableEntity
        )
      end
      authenticator_class = AUTHENTICATOR_CLASSES[type]

      return @success.new(authenticator_class.new(authenticator_dict)) if authenticator_class

      @failure.new(
        "'#{type}' authenticators are not supported.",
        status: :unprocessable_entity,
        exception: ApplicationController::UnprocessableEntity
      )
    end
  end
end
