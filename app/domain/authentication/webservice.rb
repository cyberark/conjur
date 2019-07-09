# frozen_string_literal: true

# This is here to fix a double-loading bug that occurs only in openshift and
# K8s tests.  We don't fully understand what causes the bug but this is the
# hack we settled on to fix it.

if defined? Authentication::Webservice
  return
end

require 'dry-struct'
require 'types'
require 'util/fetch_resource'

module Authentication
  class Webservice < ::Dry::Struct
    constructor_type :schema

    attribute :account,            ::Types::NonEmptyString
    attribute :authenticator_name, ::Types::NonEmptyString
    attribute :service_id,         ::Types::NonEmptyString.optional

    def self.from_string(account, str)
      type, id = *str.split('/', 2)
      self.new(account: account, authenticator_name: type, service_id: id)
    end

    def name
      [authenticator_name, service_id].compact.join('/')
    end

    def resource_id
      "#{account}:webservice:conjur/#{name}"
    end

    def resource
      @resource ||= Util::FetchResource.new.(resource_id: resource_id)
    end

    def annotation(name)
      resource&.annotation(name)
    end

    # Retrieves a Conjur variable relative to the webservice.
    # This is used to read configuration values stored as
    # Conjur secrets.
    def variable(variable_name)
      Util::FetchResource.new.(resource_id: variable_id(variable_name))
    end

    def variable_id(variable_name)
      identifier = "conjur/#{name}/#{variable_name}"
      [account, "variable", identifier].join(":")
    end
  end
end
