# The AuthenticatorConfig class maps to entries in the authenticator_configs
# database table, which stores the configuration state of Conjur authenticators.
class AuthenticatorConfig < Sequel::Model
  many_to_one :resource
end
