# frozen_string_literal: true

module Loader
  module Handlers
    # extends the policy loader to provision variable secret values. This occurs
    # after the initial policy load, when the database resources exist.
    module Provision

      # handing_provisioning records each of the resources found that include
      # the `provision/provisioner` annotation so that we can provision secret
      # values after the database resources have been created
      def handle_provisioning id
        pending_provisions << id
      end

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
          context: @context
        )
      end

      def installed_provisioners
        @installed_provisioners ||= Provisioning::InstalledProvisioners.provisioners
      end
    end
  end
end
