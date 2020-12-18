# frozen_string_literal: true

module Loader
  module Handlers
    # extends the policy loader to store role credentials (passwords). This occurs
    # after the initial policy load, since variable values are not part of the policy load
    module Provision
  
      # Passwords generated and read during policy loading for new roles cannot be immediately saved
      # because the credentials table is not part of the temporary comparison schema. So these are tracked
      # here to be saved at the end.
      def handle_provisioning id
        pending_provisions << id
      end
  
      # Store all passwords which were encountered during the policy load. The passwords aren't declared in the
      # policy itself, they are obtained from the environment. This generally only happens when setting up the
      # +admin+ user in the bootstrap phase, but setting passwords for other users can be useful for dev/test.
      def provision_values
        pending_provisions.each do |resource_id|
          resource = Resource[resource_id]

          value = Provisioning::Provision.new.(
            provision_input: provision_input(resource),
            provisioners: installed_provisioners
          )
          
          resource.push_secret(value)
        end
      end
  
      private

      def pending_provisions
        @pending_provisions ||= []
      end

      def provision_input(resource)
        provisioner_name = resource.annotation('provision/provisioner')

        Provisioning::ProvisionInput.new(
          provisioner_name: provisioner_name,
          resource: resource,
        )
      end

      def installed_provisioners
        @installed_provisioners ||= Provisioning::InstalledProvisioners.provisioners
      end
    end
  end
end
