# frozen_string_literal: true

module EdgeLogic
  module DataHandlers
    class InstallHandler
      def initialize(logger)
        @logger = logger
        @error_message = nil
      end

      def call(params, hostname, ip)
        edge = nil
        begin
          edge = Edge.get_by_hostname(hostname)
          installation_date = params.require(:installation_date)
          InstallHandler.update_installation_date(edge, installation_date)
        rescue => e
          @error_message = e.message
          raise e
        ensure
          audit_installed(edge&.name, ip)
        end
      end

      def self.update_installation_date(edge, installation_date)
        edge.update(installation_date: Time.at(installation_date))
      end

      private

      def audit_installed(edge_name = "not-found", ip)
        audit_params = { edge_name: edge_name, user: edge_name, client_ip: ip }
        audit_params[:error_message] = @error_message if @error_message
        Audit.logger.log(Audit::Event::EdgeStartup.new(
          **audit_params
        ))
      end
    end
  end
end
