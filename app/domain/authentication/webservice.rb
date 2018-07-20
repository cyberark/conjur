# frozen_string_literal: true

# This is here to fix a double-loading bug that occurs only in openshift and
# K8s tests.  We don't fully understand what causes the bug but this is the
# hack we settled on to fix it.
#
if defined? Authentication::Webservice
  return
end

require 'dry-struct'
require 'types'

module Authentication
  class Webservice < ::Dry::Struct
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
  end
end
