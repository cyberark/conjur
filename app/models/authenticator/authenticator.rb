module Authenticator
  class Authenticator
    attr_reader :account, :service_id, :required_payload_parameters

    def initialize(account:, service_id:, required_payload_parameters: nil)
      @account = account
      @service_id = service_id

      if required_payload_parameters
        if required_payload_parameters.is_a?(Array)
          @required_payload_parameters = required_payload_parameters
        else
          @required_payload_parameters = required_payload_parameters.split(" ")
        end
      end
    end

    def is_valid?
      return @account && @service_id
    end
  end
end