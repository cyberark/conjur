# frozen_string_literal: true

module ConjurAudit
  class Engine < ::Rails::Engine
    isolate_namespace ConjurAudit

    initializer :connect_audit_database do
      if config.try(:audit_database)
        db = Sequel.connect config.audit_database
        db.extension :pg_json
        Message.db.extension :pg_json
        Message.set_dataset db[:messages]
      end
    end

    config.generators do |gen|
      gen.test_framework :rspec
      gen.assets false
      gen.helper false
      gen.template_engine false
      gen.orm :sequel
    end
    
    initializer :load_sequel_extensions do
      Sequel.extension :pg_json_ops
    end
  end
end
