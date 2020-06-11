module Audit
  module Event
    # Note: Breaking this class up further would harm clarity.
    # :reek:TooManyInstanceVariables
    class Authn
      def initialize(role:, authenticator_name:, service:, success:, operation:)
        @role = role
        @authenticator_name = authenticator_name
        @service = service
        @success = success
        @operation = operation
      end

      # Note: We want this class to be responsible for providing `progname`.
      # At the same time, `progname` is currently always "conjur" and this is
      # unlikely to change.  Moving `progname` into the constructor now
      # feels like premature optimization, so we ignore reek here.
      # :reek:UtilityFunction
      def progname
        Event.progname
      end

      def severity
        RubySeverity.new(attempted_action.severity)
      end

      def authenticator_description
        return @authenticator_name unless service_id
        "#{@authenticator_name} service #{service_id}"
      end

      # TODO: See issue https://github.com/cyberark/conjur/issues/1608
      # :reek:NilCheck
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

      # TODO: See issue https://github.com/cyberark/conjur/issues/1608
      # :reek:NilCheck
      def structured_data
        {
          SDID::SUBJECT => { role: @role&.id },
          SDID::AUTH => auth_stuctured_data
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
        { authenticator: @authenticator_name }.tap do |sd|
          sd[:service] = service_id if @service
        end
      end
    end
  end
end
