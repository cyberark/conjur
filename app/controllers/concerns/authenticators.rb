# frozen_string_literal: true

# Provides the installed authenticator status for the Conjur instance
module Authenticators
  extend ActiveSupport::Concern

  AUTHN_RESOURCE_PREFIX = "conjur/authn-"

  private 

  def installed_authenticators
    @installed_authenticators ||= ::Authentication::InstalledAuthenticators.authenticators(ENV)
  end

  def configured_authenticators
    identifier = Sequel.function(:identifier, :resource_id)
    kind = Sequel.function(:kind, :resource_id)

    Resource
      .where(identifier.like("#{AUTHN_RESOURCE_PREFIX}%"))
      .where(kind => "webservice")
      .select_map(identifier)
      .map { |id| id.sub %r{^conjur\/}, "" }
      .push(::Authentication::Strategy.default_authenticator_name)
  end

  def enabled_authenticators
    (ENV["CONJUR_AUTHENTICATORS"] || ::Authentication::Strategy.default_authenticator_name).split(",")
  end

end
