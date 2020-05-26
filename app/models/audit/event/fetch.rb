# frozen_string_literal: true

module Audit
  class Event
    class Fetch < Event
      field :resource, :user, :client_ip, version: nil
      can_fail
      facility Syslog::LOG_AUTH
      message_id 'fetch'

      def success_message
        format "%s fetched %s%s", user.id, version_message_part, resource.id
      end

      def failure_message
        format "%s tried to fetch %s%s", user.id, version_message_part, resource.id
      end

      def structured_data
        super.deep_merge(
          SDID::AUTH => { user: user.id },
          SDID::SUBJECT => { resource: resource.id },
          SDID::ACTION => { operation: 'fetch' },
          SDID::CLIENT => { ip: client_ip }
        ).tap do |sd|
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
