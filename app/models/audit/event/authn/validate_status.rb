require 'forwardable'

module Audit
  module Event
    class Authn
      # NOTE: Breaking this class up further would harm clarity.
      # :reek:TooManyInstanceVariables and :reek:TooManyParameters
      class ValidateStatus
        extend Forwardable
        def_delegators(
          :@authn, :facility, :message_id, :severity, :structured_data,
          :progname
        )

        def initialize(
          role_id:,
          client_ip:,
          authenticator_name:,
          service:,
          success:,
          error_message: nil
        )
          @role_id = role_id
          @error_message = error_message
          @authn = Authn.new(
            role_id: role_id,
            client_ip: client_ip,
            authenticator_name: authenticator_name,
            service: service,
            success: success,
            operation: "validate-status"
          )
        end

        def to_s
          message
        end

        def message
          auth_description = @authn.authenticator_description
          @authn.message(
            success_msg:
              "#{@role_id} successfully validated status for authenticator "\
                "#{auth_description}",
            failure_msg:
              "#{@role_id} failed to validate status for authenticator "\
                "#{auth_description}",
            error_msg: @error_message
          )
        end
      end
    end
  end
end
