module Audit
  class Event
    class Update < Event
      field :resource, :user
      severity Syslog::LOG_NOTICE
      facility Syslog::LOG_AUTH
      message_id 'update'
      message { format "%s updated %s", user.id, resource.id }

      def structured_data
        {
          SDID::AUTH => { user: user.id },
          SDID::SUBJECT => Subject::Resource.new(resource.pk_hash).to_h,
          SDID::ACTION => { operation: 'update' }
        }
      end
    end
  end
end
