require 'types'

module Authentication
  class Webservice < ::Dry::Struct
    attribute :account,            ::Types::NonEmptyString
    attribute :authenticator_name, ::Types::NonEmptyString
    attribute :service_id,         ::Types::NonEmptyString

    def self.from_string(account, str)
      type, id = *str.split('/')
      Webservice.new(account: account, authenticator_name: type, service_id: id)
    end

    def name
      "#{authenticator_name}/#{service_id}"
    end

    def resource_id
      "#{account}:webservice:conjur/#{name}"
    end
  end
end
