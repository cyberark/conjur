require 'command_class'

module Authentication
  module ResourceRestrictions
    # Parses the given annotation name and tries to extract a restriction from it.
    # A restriction in format "<Authenticator name>/<Service ID>/<Restriction name>"
    #
    # The first format is a general restriction.
    # This means it is relevant to all services of this authenticator.
    #
    # The format is specific to the specified service ID.
    # This means all other services will ignore it.
    # Moreover, if both formats are found for the same restriction, the specific one will be used.
    #
    # This function returns the restriction name if there is service id and false, if there is no service id it returns
    # nil and true
    GetServiceSpecificRestrictionFromAnnotation = CommandClass.new(
      dependencies: {},
      inputs: %i[annotation_name authenticator_name service_id]
    ) do
      def call
        get_restriction_from_annotation
      end

      private

      def get_restriction_from_annotation
        @annotation_name.match(authenticator_prefix_regex) do |prefix_match|
          # Take the restriction name from the corresponding capture group in the match
          is_general_restriction = prefix_match[:service_id].blank?
          restriction_name = prefix_match[:restriction_name] unless is_general_restriction
          return restriction_name, is_general_restriction
        end
      end

      def authenticator_prefix_regex
        # The regex capture group <restriction_name> has the annotation name without the prefix
        @authenticator_prefix_regex ||= Regexp.new("^#{@authenticator_name}/(?<service_id>#{@service_id}/)?(?<restriction_name>[^/]+)$")
      end

    end

  end
end
