# frozen_string_literal: true

module Audit
  class Event
    class Check < Event
      field :resource, :user, :privilege, :role
      facility Syslog::LOG_AUTH
      message_id 'check'
      can_fail

      def structured_data
        super.deep_merge \
          SDID::AUTH => { user: user.id },
          SDID::SUBJECT => { resource: resource.id, role: role.id, privilege: privilege },
          SDID::ACTION => { operation: 'check' }
      end

      def message
        format "%s checked if %s can %s %s (%s)",
          user.id, role_text, privilege, resource.id, success_text
      end

      protected

      def role_text
        user == role ? 'they' : role.id
      end
    end
  end
end
