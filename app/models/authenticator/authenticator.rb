module Authenticator
  class Authenticator
    attr_reader :account, :service_id, :required_request_parameters

    def initialize(account:, service_id:, required_request_parameters: nil)
      @account = account
      @service_id = service_id

      return unless required_request_parameters

      @required_request_parameters = if required_request_parameters.is_a?(Array)
        required_request_parameters
      else
        required_request_parameters.split(" ")
      end
    end

    def valid?
      @account && @service_id
    end
  end
end
