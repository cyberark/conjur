# frozen_string_literal: true

require 'command_class'

module Provisioning

  Err = Errors::Provisioning
  # Possible Errors Raised:
  # ProvisionerNotFound

  Provision = CommandClass.new(
    dependencies: {
      audit_log:                           ::Audit.logger
    },
    inputs:       %i(provision_input provisioners)
  ) do

    def call
      validate_provisioner_exists

      provisioner.provision(@provision_input)
    end

    private

    def validate_provisioner_exists
      raise Err::ProvisionerNotFound, @provision_input.provisioner_name unless provisioner
    end

    def provisioner
      @provisioner ||= @provisioners[@provision_input.provisioner_name]
    end
  end
end
