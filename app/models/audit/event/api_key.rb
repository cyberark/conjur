module Audit
  module Event

    # Note: Breaking this class up further would harm clarity.
    # :reek:TooManyInstanceVariables and :reek:TooManyParameters
    class ApiKey
      def initialize(
        authenticated_role_id:,
        rotated_role_id:,
        client_ip:,
        success:,
        error_message: nil
      )
        @authenticated_role_id = authenticated_role_id
        @rotated_role_id = rotated_role_id
        @client_ip = client_ip
        @success = success
        @error_message = error_message

        # Implements `==` for audit events
        @comparable_evt = ComparableEvent.new(self)
      end

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
        attempted_action.message(
          success_msg: success_message,
          failure_msg: failure_message,
          error_msg: @error_message
        )
      end

      def message_id
        'api-key'
      end

      def structured_data
        {
          SDID::AUTH => { user: @authenticated_role_id },
          SDID::SUBJECT => { role: @rotated_role_id },
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

      def success_message
        if user_rotating_their_own_key?
          "#{@authenticated_role_id} successfully rotated their API key"
        else
          "#{@authenticated_role_id} successfully rotated the api key for #{@rotated_role_id}"
        end
      end

      def failure_message
        if user_rotating_their_own_key?
          "#{@authenticated_role_id} failed to rotate their API key"
        else
          "#{@authenticated_role_id} failed to rotate the api key for #{@rotated_role_id}"
        end
      end
      
      # True if the role requesting the rotation is the same role
      # the rotation is for. In other words, when you rotate your own
      # API key
      def user_rotating_their_own_key?
        @authenticated_role_id == @rotated_role_id
      end

      def attempted_action
        @attempted_action ||= AttemptedAction.new(
          success: @success,
          operation: 'rotate'
        )
      end
    end
  end
end
