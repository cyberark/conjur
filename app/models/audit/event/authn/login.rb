require 'forwardable'

module Audit
  module Event
    class Authn
      class Login
        extend Forwardable
        def_delegators(
          :@authn, :facility, :message_id, :severity, :structured_data,
          :progname
        )

        def initialize(
          role:,
          authenticator_name:,
          service:,
          success:,
          error_message: nil
        )
          @role = role
          @error_message = error_message
          @authn = Authn.new(
            role: role,
            authenticator_name: authenticator_name,
            service: service,
            success: success,
            operation: "login"
          )
        end

        def to_s
          message
        end

        # TODO: See issue https://github.com/cyberark/conjur/issues/1608
        # :reek:NilCheck
        def message
          auth_description = @authn.authenticator_description
          @authn.message(
            success_msg:
              "#{@role&.id} successfully logged in with authenticator " \
                "#{auth_description}",
            failure_msg:
              "#{@role&.id} failed to login with authenticator " \
                "#{auth_description}",
            error_msg: @error_message
          )
        end
      end
    end
  end
end
