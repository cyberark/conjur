module Audit
  module Event
    # NOTE: Breaking this class up further would harm clarity.
    # :reek:TooManyInstanceVariables and :reek:TooManyParameters
    class Fetch
      def initialize(
        user:,
        client_ip:,
        resource_id:,
        success:,
        version:,
        operation:,
        error_message: nil
      )
        @user = user
        @client_ip = client_ip
        @resource_id = resource_id
        @success = success
        @error_message = error_message
        @version = version
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
        user_id = @user.id
        attempted_action.message(
          success_msg: "#{user_id} fetched #{resource_description}",
          failure_msg: "#{user_id} tried to fetch #{resource_description}",
          error_msg: @error_message
        )
      end

      def message_id
        "fetch"
      end

      def structured_data
        {
          SDID::AUTH => { user: @user.id },
          SDID::SUBJECT => subject_sd_value,
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

      def resource_description
        @version ? versioned_resource_description : @resource_id
      end

      def versioned_resource_description
        "version #{@version} of #{@resource_id}"
      end

      def subject_sd_value
        { resource: @resource_id }.tap do |sd|
          if @version
            sd[:version] = @version
          end
        end
      end

      def attempted_action
        @attempted_action ||= AttemptedAction.new(
          success: @success,
          operation: @operation
        )
      end

    end
  end
end
