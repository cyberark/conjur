module Audit
  module Event
    class Whoami

      # NOTE: "role" may refer to a user or host.
      def initialize(
        client_ip:,
        role:,
        success:
      )
        @client_ip = client_ip
        @role = role
        @success = success

        # Implements `==` for audit events
        @comparable_evt = ComparableEvent.new(self)
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

      def to_s
        message
      end

      def message
        "#{role_id} checked its identity using whoami"
      end

      def message_id
        'identity-check'
      end

      def structured_data
        {
          SDID::SUBJECT => { role: role_id },
          SDID::AUTH => { user: role_id },
          SDID::CLIENT => { ip: @client_ip }
        }.merge(
          attempted_action.action_sd
        )
      end

      def facility
        Syslog::LOG_AUTH
      end

      def ==(other)
        @comparable_evt == other
      end

      # action_sd means "action structured data"
      def action_sd
        attempted_action.action_sd
      end

      private

      def attempted_action
        @attempted_action ||= AttemptedAction.new(
          success: @success,
          operation: 'check'
        )
      end

      def role_id
        @role_id ||= @role&.role_id
      end
    end
  end
end
