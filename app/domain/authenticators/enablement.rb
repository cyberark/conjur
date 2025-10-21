module Authenticators
  class Enablement

    def initialize(
      enabled:
    )
      @enabled = enabled
      @success = Responses::Success
      @failure = Responses::Failure
      @context = AuthenticatorController::Current
    end

    def update_enablement_status(type:, account:, service_id:) 
      config_input = update_config_input(type, account, service_id)
      begin
        @success.new(
          Authentication::UpdateAuthenticatorConfig.new.(
            update_config_input: config_input
          )
        )
      rescue Errors::Authentication::Security::WebserviceNotFound => e
        resource_id = "#{type}/#{service_id}"
        @failure.new(
          "Authenticator: #{resource_id} not found in account '#{account}'",
          status: :not_found,
          exception: e
        )
      rescue Errors::Authentication::Security::RoleNotAuthorizedOnResource => e
        @failure.new(
          e.message,
          status: :forbidden,
          exception: e
        )
      end
    end
  
    def update_config_input(type, account, service_id)
      @update_config_input ||= Authentication::UpdateAuthenticatorConfigInput.new(
        account: account,
        authenticator_name: type,
        service_id: service_id,
        username: ::Role.username_from_roleid(@context.user.role_id),
        enabled: @enabled.to_s,
        client_ip: @context.request.ip
      )
    end

    class << self
      def from_input(input)
        parse_input(input).bind do |enablement|
          Responses::Success.new(
            new(enabled: enablement)
          )
        end
      end
    
      def required_key?(body)
        body.key?(:enabled)
      end
    
      def extra_keys?(keys, required)
        collect_extra_keys(keys, required).count.positive?
      end
    
      def bool?(field)
        field.in?([true, false])
      end

      def collect_extra_keys(keys, required)
        keys.tap do |k| 
          required.each { |r| k.delete(r) }
        end
      end

      def parse_input(input)
        if !required_key?(input)
          missing_param(:enabled)
        elsif extra_keys?(input.keys, [:enabled])
          extra_keys(input.keys, [:enabled])
        elsif !bool?(input[:enabled])
          mismatch_type("enabled", "boolean")
        else
          Responses::Success.new(input[:enabled])
        end
      end

      def missing_param(param)
        Responses::Failure.new(
          "Missing required parameter: #{param}",
          status: :unprocessable_entity
        )
      end

      def extra_keys(keys, required)
        extra_keys = collect_extra_keys(keys, required).compact.join(', ')
        
        Responses::Failure.new(
          "The following parameters were not expected: '#{extra_keys}'",
          status: :unprocessable_entity
        )
      end

      def mismatch_type(param, type)
        Responses::Failure.new(
          "The #{param} parameter must be of type=#{type}",
          status: :unprocessable_entity
        )
      end
    end
  end
end
