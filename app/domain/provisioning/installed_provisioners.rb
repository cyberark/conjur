# frozen_string_literal: true

module Provisioning
  class InstalledProvisioners

    def self.provisioners(provisioning_module: ::Provisioning)
      loaded_provisioners(provisioning_module)
        .select { |cls| valid?(cls) }
        .map { |cls| [annotation_name_for(cls), cls.new] }
        .to_h
    end

    private

    def self.loaded_provisioners(provisioning_module)
      ::Util::Submodules.of(provisioning_module)
        .flat_map { |mod| ::Util::Submodules.of(mod) }
    end

    def self.annotation_name_for(cls) 
      ::Provisioning::ProvisionerClass.new(cls).annotation_name
    end

    def self.valid?(cls)
      ::Provisioning::ProvisionerClass::Validation.new(cls).valid?
    end
  end
end
