module Audit
  module Event

    NOT_FOUND = "not-found".freeze

    # NOTE: Breaking this class up further would harm clarity.
    # :reek:TooManyInstanceVariables and :reek:TooManyParameters
    class Authn
      def initialize(
        role_id:,
        client_ip:,
        authenticator_name:,
        service:,
        success:,
        operation:
      )
        @role_id = role_id
        @client_ip = client_ip
        @authenticator_name = authenticator_name
        @service = service
        @success = success
        @operation = operation
      end

      # NOTE: We want this class to be responsible for providing `progname`.
      # At the same time, `progname` is currently always "conjur" and this is
      # unlikely to change.  Moving `progname` into the constructor now
      # feels like premature optimization, so we ignore reek here.
      # :reek:UtilityFunction
      def progname
        Event.progname
      end

      def severity
        attempted_action.severity
      end

      def authenticator_description
        return @authenticator_name unless service_id

        "#{@authenticator_name} service #{service_id}"
      end

      def service_id
        @service&.resource_id
      end

      def message(success_msg:, failure_msg:, error_msg: nil)
        attempted_action.message(
          success_msg: success_msg,
          failure_msg: failure_msg,
          error_msg: error_msg
        )
      end

      def message_id
        "authn"
      end

      def structured_data
        {
          SDID::SUBJECT => { role: @role_id },
          SDID::AUTH => auth_stuctured_data,
          SDID::CLIENT => { ip: @client_ip }
        }.merge(
          attempted_action.action_sd
        )
      end

      def facility
        # Security or authorization messages which should be kept private. See:
        # https://github.com/ruby/ruby/blob/b753929806d0e42cdfde3f1a8dcdbf678f937e44/ext/syslog/syslog.c#L109
        Syslog::LOG_AUTHPRIV
      end

      private

      def attempted_action
        @attempted_action ||= AttemptedAction.new(
          success: @success,
          operation: @operation
        )
      end

      def auth_stuctured_data
        { user: sanitized_role_id }.tap do |sd|
          sd[:authenticator] = @authenticator_name
          sd[:service] = service_id if @service
        end
      end

      # Masking role if it doesn't exist to avoid audit pollution
      # Checking @success as well to save DB call on success
      def sanitized_role_id
        return NOT_FOUND unless @success || Role[role_id: @role_id]

        @role_id
      end
    end
  end
end
