require 'conjur/audit/webservice'

module Conjur
  module Audit
    # Ideally this would be an engine but this requires directory
    # structure like a rails app and that'd be a bit of an overkill for now.
    class Railtie < ::Rails::Railtie
      config.audit_database = ENV['AUDIT_DATABASE_URL']
      initializer :connect_audit_database do |app|
        if config.audit_database
          db = Sequel.connect config.audit_database
          @app = Conjur::Audit::Webservice.new db[:messages]
        end
      end

      attr_reader :app
    end
  end
end

