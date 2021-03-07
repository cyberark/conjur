module Audit
  module Event
    # Note: Breaking this class up further would harm clarity.
    # :reek:TooManyInstanceVariables and :reek:TooManyParameters
    class Check
      def initialize(
        user:,
        client_ip:,
        resource_id:,
        privilege:,
        role_id:,
        operation:,
        success:,
        error_message: nil
      )
        @user = user
        @client_ip = client_ip
        @resource_id = resource_id
        @privilege = privilege
        @role_id = role_id
        @operation = operation
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

      def message
        "#{@user.id} #{result_text} if #{role_text} can #{@privilege} " \
          "#{@resource_id} #{error_message_text}"
      end

      def message_id
        "check"
      end

      def structured_data
        {
          SDID::AUTH => { user: @user.id },
          SDID::SUBJECT => {
            resource: @resource_id,
            role: @role_id,
            privilege: @privilege
          },
          SDID::CLIENT => { ip: @client_ip }
        }.merge(
          attempted_action.action_sd
        )
      end

      # action_sd means "action structured data"
      def action_sd
        attempted_action.action_sd
      end

      def facility
        # Security or authorization messages which should be kept private. See:
        # https://github.com/ruby/ruby/blob/b753929806d0e42cdfde3f1a8dcdbf678f937e44/ext/syslog/syslog.c#L109
        # Note: Changed this to from LOG_AUTH to LOG_AUTHPRIV because the former
        # is deprecated.
        Syslog::LOG_AUTHPRIV
      end

      private

      def attempted_action
        @attempted_action ||= AttemptedAction.new(
          success: @success,
          operation: @operation
        )
      end

      def role_text
        @user.id == @role_id ? 'they' : @role_id
      end

      def result_text
        @success ? "successfully checked" : "failed to check"
      end

      def error_message_text
        @error_message ? ": #{@error_message}" : ""
      end
    end
  end
end
