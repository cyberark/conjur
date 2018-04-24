require 'types'

module Authentication
  class Webservice < ::Dry::Struct
    attribute :account,    ::Types::NonEmptyString
    attribute :authn_type, ::Types::NonEmptyString
    attribute :service_id, ::Types::NonEmptyString

    def self.from_string(account, str)
      type, id = *str.split('/')
      Webservice.new(account: account, authn_type: type, service_id: id)
    end

    def name
      "#{authn_type}/#{service_id}"
    end

    def resource_id
      "#{account}:webservice:conjur/#{name}"
    end
  end
end
