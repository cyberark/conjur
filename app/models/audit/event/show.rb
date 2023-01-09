module Audit
  module Event
    # NOTE: Breaking this class up further would harm clarity.
    # :reek:TooManyInstanceVariables and :reek:TooManyParameters
    class Show

      attr_reader :message_id

      def initialize(
        user_id:,
        client_ip:,
        subject:,
        message_id:,
        success:,
        error_message: nil
      )
        @user_id = user_id
        @subject = subject
        @client_ip = client_ip
        @success = success
        @message_id=message_id
        @error_message = error_message

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

      # action_sd means "action structured data"
      def action_sd
        attempted_action.action_sd
      end

      def severity
        attempted_action.severity
      end

      def to_s
        message
      end

      def message
        attempted_action.message(
          success_msg: "#{@user_id} successfully fetched #{message_id} details.",
          failure_msg: "#{@user_id} failed to fetch #{message_id} details",
          error_msg: @error_message
        )
      end

      def structured_data
        {
          SDID::AUTH => { user: @user_id },
          SDID::SUBJECT => @subject,
          SDID::CLIENT => { ip: @client_ip }
        }.merge(
          attempted_action.action_sd
        )
      end

      def facility
        # Security or authorization messages which should be kept private. See:
        # https://github.com/ruby/ruby/blob/master/ext/syslog/syslog.c#L109
        # Note: Changed this to from LOG_AUTH to LOG_AUTHPRIV because the former
        # is deprecated.
        Syslog::LOG_AUTHPRIV
      end

      def ==(other)
        @comparable_evt == other
      end

      private

      def attempted_action
        @attempted_action ||= AttemptedAction.new(
          success: @success,
          operation: 'get'
        )
      end
    end
  end
end
