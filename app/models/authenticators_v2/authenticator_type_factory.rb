# frozen_string_literal: true

module AuthenticatorsV2
  class AuthenticatorTypeFactory
    def initialize
      @success = Responses::Success
      @failure = Responses::Failure
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
    # @param [Object] auth_dict - Object containing authenticator parameters
    #
    # @return [JwtAuthenticatorType] if type is "authn-jwt"
    # @return [OidcAuthenticatorType] if type is "authn-oidc"
    # @return [LdapAuthenticatorType] if type is "authn-ldap"
    # @return [K8sAuthenticatorType] if type is "authn-k8s"
    # @return [AwsAuthenticatorType] if type is "authn-iam"
    # @return [AzureAuthenticatorType] if type is "authn-azure"
    # @return [GcpAuthenticatorType] if type is "authn-gcp"
    # @raise  [ApplicationController::UnprocessableEntity] if type is nil or unsupported
    def call(auth_dict)
      select_auth_klass(auth_dict[:type]).bind do |klass|
        @success.new(klass.new(auth_dict))
      end
    end

    private

    def select_auth_klass(type)
      if type.nil?
        return @failure.new(
          "Authenticator type is required",
          status: :unprocessable_entity,
          exception: ApplicationController::UnprocessableEntity
        )
      end
      klass = AUTHENTICATOR_CLASSES[type]

      return @success.new(klass) if klass
       
      @failure.new(
        "'#{type}' authenticators are not supported.",
        status: :unprocessable_entity,
        exception: ApplicationController::UnprocessableEntity
      )
    end
  end
end
