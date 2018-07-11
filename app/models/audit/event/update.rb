# frozen_string_literal: true

module Audit
  class Event
    class Update < Event
      field :resource, :user
      can_fail
      severity { success ? Syslog::LOG_NOTICE : Syslog::LOG_WARNING }
      facility Syslog::LOG_AUTH
      message_id 'update'
      success_message { format "%s updated %s", user.id, resource.id }
      failure_message { format "%s tried to update %s", user.id, resource.id }

      def structured_data
        super.deep_merge \
          SDID::AUTH => { user: user.id },
          SDID::SUBJECT => Subject::Resource.new(resource.pk_hash).to_h,
          SDID::ACTION => { operation: 'update' }
      end
    end
  end
end
