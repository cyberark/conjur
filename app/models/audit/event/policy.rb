require 'audit/event'

module Audit
  class Event
    class Policy < Event
      field :policy_version, :operation, :subject
      severity Syslog::LOG_NOTICE
      facility Syslog::LOG_AUTH
      message_id 'policy'

      message { format "%s %sed %s", user_id, operation.to_s.chomp('e'), subject }

      def structured_data
        {
          SDID::AUTH => { user: user_id },
          SDID::POLICY => { id: policy_version.id, version: policy_version.version },
          SDID::SUBJECT => subject.to_h,
          SDID::ACTION => { operation: operation }
        }
      end

      private

      def user_id
        @user_id ||= policy_version.role.id
      end
    end
  end
end
