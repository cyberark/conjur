module Audit
  class Event
    class Fetch < Event
      field :resource, :user, version: nil
      severity Syslog::LOG_INFO
      facility Syslog::LOG_AUTH
      message_id 'fetch'
      message { format "%s fetched %s%s", user.id, version_message_part, resource.id }

      def structured_data
        {
          SDID::AUTH => { user: user.id },
          SDID::SUBJECT => { resource: resource.id },
          SDID::ACTION => { operation: 'fetch' }
        }.tap do |sd|
          sd[SDID::SUBJECT][:version] = version if version
        end
      end

      private

      def version_message_part
        format "version %d of ", version if version
      end
    end
  end
end
