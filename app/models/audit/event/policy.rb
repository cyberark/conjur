require 'audit/event'

module Audit
  class Event
    class Policy < Event
      field :operation, :subject, policy_version: nil, user: nil
      severity Syslog::LOG_NOTICE
      facility Syslog::LOG_AUTH
      message_id 'policy'

      message { format "%s %sed %s", user_id, operation.to_s.chomp('e'), subject }

      def structured_data
        {
          SDID::AUTH => { user: user_id },
          SDID::SUBJECT => subject.to_h,
          SDID::ACTION => { operation: operation }
        }.tap do |sd|
          if policy_version
            sd[SDID::POLICY] = { 
              id: policy_version.id, 
              version: policy_version.version
            }
          end
        end
      end

      private
      
      def user_id
        @user_id ||= user.id
      end

      def user
        @user ||= super || policy_version.role
      end
    end
  end
end
