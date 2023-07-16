# frozen_string_literal: true

module EdgeLogic
  module DataHandlers
    class InstallHandler
      def initialize(logger)
        @logger = logger
      end

      def call(params, hostname, ip)
        installation_date = params.require(:installation_date)
        edge = Edge.get_by_hostname(hostname)
        edge.update(installation_date: Time.at(installation_date))

        #TODO write audit
      end
    end
  end
end
