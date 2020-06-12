module Audit
  module Event
    class Password

      def initialize(user:, success:, error_message: nil)
        @user = user
        @success = success
        @error_message = error_message
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
        attempted_action.severity
      end

      def to_s
        message
      end

      # It's clearer to simply call the #id attribute multiple times, rather
      # than factor it out, even though it reeks of :reek:DuplicateMethodCall
      def message
        attempted_action.message(
          success_msg: "#{@user.id} successfully changed their password",
          failure_msg: "#{@user.id} failed to change their password",
          error_msg: @error_message
        )
      end

      def message_id
        'password'
      end

      # It's clearer to simply call the #id attribute multiple times, rather
      # than factor it out, even though it reeks of :reek:DuplicateMethodCall
      def structured_data
        {
          SDID::AUTH => { user: @user.id },
          SDID::SUBJECT => { user: @user.id }
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

      private

      def attempted_action
        @attempted_action ||= AttemptedAction.new(
          success: @success,
          operation: 'change'
        )
      end
    end
  end
end
