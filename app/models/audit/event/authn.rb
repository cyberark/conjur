module Audit
  class Event
    class Authn < Event
      field :role, :authenticator_name, service: nil
      facility Syslog::LOG_AUTHPRIV
      message_id 'authn'
      can_fail

      def structured_data
        super.deep_merge \
          SDID::SUBJECT => { role: role_id },
          SDID::AUTH => auth_sd,
          SDID::ACTION => { operation: 'authenticate' }
      end

      def success_message
        format "%s successfully authenticated with authenticator %s%s",
          role_id, authenticator_name, service_message_part
      end

      def failure_message
        format "%s failed to authenticate with authenticator %s%s",
          role_id, authenticator_name, service_message_part
      end

      protected

      def service_message_part
        " service #{service_id}" if service_id
      end

      def role_id
        role.id
      end

      def service_id
        service && service.id
      end

      def auth_sd
        { authenticator: authenticator_name }.tap do |result|
          result[:service] = service_id if service_id
        end
      end
    end
  end
end
