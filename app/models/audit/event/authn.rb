# frozen_string_literal: true

module Audit
  class Event
    class Authn < Event
      abstract_field :success_message, :failure_message, :operation

      field :role, :authenticator_name, service: nil
      
      facility Syslog::LOG_AUTHPRIV
      message_id 'authn'
      can_fail

      def structured_data
        super.deep_merge \
          SDID::SUBJECT => { role: role_id },
          SDID::AUTH => auth_sd,
          SDID::ACTION => { operation: operation }
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
