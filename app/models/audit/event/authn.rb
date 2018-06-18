module Audit
  class Event
    class Authn < Event
      field :role, :authenticator_name, service: nil
      facility Syslog::LOG_AUTHPRIV
      message_id 'authn'

      def structured_data
        {
          SDID::SUBJECT => { role: role_id },
          SDID::AUTH => auth_sd,
          SDID::ACTION => { operation: 'authenticate' }
        }
      end

      def success
        Success.new to_h
      end

      def failure error_message
        Failure.new to_h.merge error_message: error_message
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

      class Success < Authn
        severity Syslog::LOG_INFO

        def message
          format "%s successfully authenticated with authenticator %s%s",
            role_id, authenticator_name, service_message_part
        end

        def structured_data
          super.tap do |sd|
            sd[SDID::ACTION][:result] = 'success'
          end
        end
      end

      class Failure < Authn
        field :error_message
        severity Syslog::LOG_WARNING

        def message
          format "%s failed to authenticate with authenticator %s%s: %s",
            role_id, authenticator_name, service_message_part, error_message
        end

        def structured_data
          super.tap do |sd|
            sd[SDID::ACTION][:result] = 'failure'
          end
        end
      end
    end
  end
end
