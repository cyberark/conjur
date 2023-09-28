# frozen_string_literal: true

module EdgeLogic
  module DataHandlers
    class OngoingHandler

      include ParamsValidator
      def initialize(logger)
        @logger = logger
      end

      def call(params, hostname, ip)
        params.require(:edge_statistics).require(:last_synch_time)
        allowed_params = [:edge_version, :edge_container_type, edge_statistics: [:last_synch_time, cycle_requests:
          [:get_secret, :apikey_authenticate, :jwt_authenticate, :redirect]]]
        options = params.permit(*allowed_params).to_h
        validate_params(options, input_validator)

        edge = Edge.get_by_hostname(hostname)
        InstallHandler.update_installation_date(edge, -1) unless edge.installation_date
        edge.record_edge_access(options, ip)
        # Log Edge statistics to be collected by Datadog
        stats = options['edge_statistics']
        cycle_reqs = stats['cycle_requests'] || {}
        #convert time to seconds 
        last_synch_time_sec = Rational(stats['last_synch_time'], 1000)
        installation_time_sec = Rational(edge.installation_date, 1000)
        @logger.info(LogMessages::Edge::EdgeTelemetry.new(tenant_id, edge.name, Time.at(last_synch_time_sec),
                                                         cycle_reqs['get_secret'], cycle_reqs['apikey_authenticate'],
                                                         cycle_reqs['jwt_authenticate'], cycle_reqs['redirect'],
                                                         edge.version, edge.platform, Time.at(installation_time_sec)))
      end

      def input_validator
        @input_validator ||= ->(k, v) {
          case k.to_sym
          when :edge_version
            v.match?(/^[0-9.v]+$/)
          when :edge_container_type
            %w[podman docker].include?(v.downcase)
          when :last_synch_time, :cycle_requests, :get_secret, :apikey_authenticate, :jwt_authenticate, :redirect
            numeric_validator.call(k, v)
          else
            numeric_validator.call(k, v) || string_length_validator.call(k, v)
          end
        }
      end

      private

      def tenant_id
        Rails.application.config.conjur_config.tenant_id
      end

    end
  end
end
