# frozen_string_literal: true

Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    'rbac' => 'RBAC',
    'db' => 'DB',
    'api_validator' => 'APIValidator',
    'cidr' => 'CIDR',
    'rfc5424_formatter' => 'RFC5424Formatter',
    'ca' => 'CA',
    'conjur_ca' => 'ConjurCA',
    'jwt_authenticator_input' => 'JWTAuthenticatorInput',
    'configuration_jwt_generic_vendor' => 'ConfigurationJWTGenericVendor',
    'sdid' => 'SDID'
  )
end
