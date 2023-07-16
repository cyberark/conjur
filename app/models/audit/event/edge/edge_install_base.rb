module Audit
  module Event
    # NOTE: Breaking this class up further would harm clarity.
    # :reek:TooManyInstanceVariables and :reek:TooManyParameters
    class EdgeInstallBase

      def initialize(
        edge_name:,
        user: nil,
        client_ip: nil,
        error_message: nil
      )
        @edge_name = edge_name
        @user = user
        @client_ip = client_ip
        @error_message = error_message
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
        Syslog::LOG_NOTICE
      end

      def to_s
        message
      end

      # TODO: See issue https://github.com/cyberark/conjur/issues/1608
      # :reek:NilCheck
      def message
        attempted_action.message(
          success_msg: success_message,
          failure_msg: failure_message,
          error_msg: @error_message
        )
      end

      def message_id
        raise NotImplementedError, "Subclasses must implement abstract_method."
      end

      def operation
        raise NotImplementedError, "Subclasses must implement abstract_method."
      end

      def attempted_action
        @attempted_action ||= AttemptedAction.new(
          success: success?,
          operation: operation
        )
      end

      # TODO: See issue https://github.com/cyberark/conjur/issues/1608
      # :reek:NilCheck
      def structured_data
        {
          SDID::AUTH => { user: @user },
          SDID::SUBJECT => {edge: @edge_name},
          SDID::CLIENT => { ip: @client_ip }
        }.merge(
          attempted_action.action_sd
        )
      end

      def facility
        # Security or authorization messages which should be kept private. See:
        # https://github.com/ruby/ruby/blob/b753929806d0e42cdfde3f1a8dcdbf678f937e44/ext/syslog/syslog.c#L109
        # Note: Changed this to from LOG_AUTH to LOG_AUTHPRIV because the former
        # is deprecated.
        Syslog::LOG_AUTHPRIV
      end

      private

      def success_message
        raise NotImplementedError, "Subclasses must implement abstract_method."
      end

      def failure_message
        raise NotImplementedError, "Subclasses must implement abstract_method."
      end

      def success?
        @error_message.nil?
      end
    end
  end
end
