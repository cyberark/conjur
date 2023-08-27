module Audit
  module Event
    # NOTE: Breaking this class up further would harm clarity.
    # :reek:TooManyInstanceVariables and :reek:TooManyParameters
    class IssuerVariable

      def initialize(
        user_id:,
        client_ip:,
        subject:,
        message_id:,
        success:,
        operation:,
        error_message: nil
      )
        @user_id = user_id
        @client_ip = client_ip
        @subject = subject
        @message_id = message_id
        @success = success
        @operation = operation
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
        # NOTE: original, incorrect logic, just in case we need it:
        #
        #   @success ? Syslog::LOG_NOTICE : Syslog::LOG_WARNING
        #
        # The incorrect part was that a success was logged as LOG_NOTICE rather
        # than LOG_INFO.  This comment added June 10, 2020.  Future developers
        # may safely remove it if more than a couple months have elapsed.
        attempted_action.severity
      end

      def to_s
        message
      end

      def message
        attempted_action.message(
          success_msg: "#{@subject[:resource_id]} removed as a result of the removal of #{@subject[:account]}:issuer:#{@subject[:issuer]}",
          failure_msg: "failed to remove #{@subject[:resource_id]}, following the removal of #{@subject[:account]}:issuer:#{@subject[:issuer]}",
          error_msg: @error_message
        )
      end

      def message_id
        @message_id
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
        # https://github.com/ruby/ruby/blob/b753929806d0e42cdfde3f1a8dcdbf678f937e44/ext/syslog/syslog.c#L109
        # Note: Changed this to from LOG_AUTH to LOG_AUTHPRIV because the former
        # is deprecated.
        Syslog::LOG_AUTHPRIV
      end

      # action_sd means "action structured data"
      def action_sd
        attempted_action.action_sd
      end

      private

      def attempted_action
        @attempted_action ||= AttemptedAction.new(
          success: @success,
          operation: @operation
        )
      end

    end
  end
end
