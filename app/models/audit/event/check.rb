module Audit
  class Event
    class Check < Event
      field :resource, :user, :privilege, :role, :success
      facility Syslog::LOG_AUTH
      severity { success ? Syslog::LOG_INFO : Syslog::LOG_WARNING }
      message_id 'check'

      def structured_data
        {
          SDID::AUTH => { user: user.id },
          SDID::SUBJECT => { resource: resource.id, role: role.id, privilege: privilege },
          SDID::ACTION => { operation: 'check', result: success_text }
        }
      end

      def message
        format "%s checked if %s can %s %s (%s)",
          user.id, role_text, privilege, resource.id, success_text
      end

      protected

      def success_text
        success ? 'success' : 'failure'
      end

      def role_text
        user == role ? 'they' : role.id
      end
    end
  end
end
