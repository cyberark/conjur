require 'command_class'

module Authentication
  module ResourceRestrictions

    FetchResourceAnnotations = CommandClass.new(
      dependencies: {
        role_class: ::Role,
        resource_class: ::Resource
      },
      inputs: %i[account role_name ignore_empty_annotations]
    ) do

      def call
        fetch_resource_annotations
      end

      private

      def fetch_resource_annotations
        resource_annotations
      end

      def resource_annotations
        resource.annotations.each_with_object({}) do |annotation, result|
          annotation_values = annotation.values
          value = annotation_values[:value]
          next if value.blank? and @ignore_empty_annotations

          result[annotation_values[:name]] = value
        end
      end

      def resource
        return @resource if @resource

        @resource = @resource_class[role_id]
        raise Errors::Authentication::Security::RoleNotFound, role_id unless @resource
        @resource
      end

      def role_id
        @role_id ||= @role_class.roleid_from_username(@account, @role_name)
      end

    end
  end
end
