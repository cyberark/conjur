module Audit
  module Event
    # NOTE: Breaking this class up further would harm clarity.
    # :reek:TooManyInstanceVariables and :reek:TooManyParameters
    class Policy

      def initialize(
        operation:,
        subject:,
        user: nil,
        policy_version: nil,
        client_ip: nil,
        error_message: nil
      )
        @operation = operation
        @subject = subject
        @user = user
        @policy_version = policy_version
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
          failure_msg: "Failed to load policy",
          error_msg: @error_message
        )
      end

      def message_id
        "policy"
      end

      def attempted_action
        @attempted_action ||= AttemptedAction.new(
          success: success?,
          operation: @operation
        )
      end

      # TODO: See issue https://github.com/cyberark/conjur/issues/1608
      # :reek:NilCheck
      def structured_data
        {
          SDID::AUTH => { user: user&.id },
          SDID::SUBJECT => @subject.to_h,
          SDID::CLIENT => { ip: client_ip }
        }.merge(
          attempted_action.action_sd
        ).tap do |sd|
          if @policy_version
            sd[SDID::POLICY] = {
              id: @policy_version.id,
              version: @policy_version.version
            }
          end
        end
      end

      def facility
        # Security or authorization messages which should be kept private. See:
        # https://github.com/ruby/ruby/blob/b753929806d0e42cdfde3f1a8dcdbf678f937e44/ext/syslog/syslog.c#L109
        # Note: Changed this to from LOG_AUTH to LOG_AUTHPRIV because the former
        # is deprecated.
        Syslog::LOG_AUTHPRIV
      end

      def subject
        @subject
      end

      def operation
        @operation
      end

      private

      def success_message
        past_tense_verb = "#{@operation.to_s.chomp('e')}ed"
        "#{user&.id} #{past_tense_verb} #{@subject}"
      end

      def user
        @user || @policy_version&.role
      end

      def client_ip
        @client_ip || @policy_version&.client_ip
      end

      def success?
        @error_message.nil?
      end
    end
  end
end
