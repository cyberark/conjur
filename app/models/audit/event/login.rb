# frozen_string_literal: true

module Audit
  class Event
    class Login < Event
      field :role, :authenticator_name, service: nil
      facility Syslog::LOG_AUTHPRIV
      message_id 'login'
      can_fail

      def structured_data
        super.deep_merge \
          SDID::SUBJECT => { role: role_id },
          SDID::AUTH => auth_sd,
          SDID::ACTION => { operation: 'login' }
      end

      def success_message
        format "%s successfully logged-in with authenticator %s%s",
          role_id, authenticator_name, service_message_part
      end

      def failure_message
        format "%s failed to log in with authenticator %s%s",
          role_id, authenticator_name, service_message_part
      end

      protected

      def service_message_part
        service&.id ? " service #{service.id}" : nil
      end

      def role_id
        role.id
      end

      def auth_sd
        { authenticator: authenticator_name }.tap do |result|
          result[:service] = service.id  if service&.id
        end
      end
    end
  end
end
