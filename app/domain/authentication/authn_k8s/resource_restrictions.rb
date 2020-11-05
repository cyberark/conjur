# frozen_string_literal: true

module Authentication
  module AuthnK8s

    # This class represents the restrictions that are set on a Conjur host regarding
    # the K8s resources that it can authenticate with Conjur from.
    # It consists a list of K8sResource objects which represent the resource
    # restriction that need to be met in an authentication request.
    #
    # For example, if `resources` includes the K8sResource:
    #   - type: "namespace"
    #   - value: "some-namespace"
    #
    # then this Conjur host can authenticate with Conjur only from a pod that is
    # part of the namespace "some-namespace".
    #
    # In authn-k8s, the resource restrictions can be defined in the host's id
    # or in the host's annotations
    class ResourceRestrictions

      attr_reader :resources

      K8S_RESOURCE_TYPES = %w(namespace service-account pod deployment stateful-set deployment-config).freeze
      AUTHENTICATION_CONTAINER_NAME_ANNOTATION = "authentication-container-name"

      def initialize(host_id:, host_annotations:, service_id:, logger:)
        @host_id          = host_id
        @host_annotations = host_annotations
        @service_id       = service_id
        @logger           = logger

        init_resources
        validate_configuration
      end

      private

      def init_resources
        @resources = K8S_RESOURCE_TYPES.each_with_object([]) do |resource_type, resources|
          resource_value = resource_value(resource_type)
          next unless resource_value
          resources.push(
            K8sResource.new(
              type: resource_type,
              value: resource_value
            )
          )
        end
      end

      def validate_configuration
        validate_constraints_are_permitted
        validate_required_constraints_exist
        validate_constraint_combinations
      end

      def resource_value resource_type
        resource_restrictions_in_annotations? ? resource_from_annotation(resource_type) : resource_from_id(underscored_k8s_resource_type(resource_type))
      end

      def resource_from_annotation resource_type
        annotation_value("authn-k8s/#{@service_id}/#{resource_type}") ||
          annotation_value("authn-k8s/#{resource_type}")
      end

      def annotation_value name
        annotation = @host_annotations.find { |a| a.values[:name] == name }

        # return the value of the annotation if it exists, nil otherwise
        if annotation
          @logger.debug(LogMessages::Authentication::ResourceRestrictions::RetrievedAnnotationValue.new(name))
          annotation[:value]
        end
      end

      # If the resource restrictions are defined in:
      #   - annotations: validates that all the constraints are
      #                  valid (e.g there is no "authn-k8s/blah" annotation)
      #   - host id: validates that the host-id has 3 parts and that the given
      #              constraint is valid (e.g the host id is not
      #              "namespace/blah/some-value")
      def validate_constraints_are_permitted
        resource_restrictions_in_annotations? ? validate_permitted_annotations : validate_host_id
      end

      # We expect the resource restrictions to be defined by the host's annotations
      # if any of the constraint annotations is present.
      def resource_restrictions_in_annotations?
        @resource_restrictions_in_annotations ||= K8S_RESOURCE_TYPES.any? do |resource_type|
          resource_from_annotation(resource_type)
        end
      end

      def validate_permitted_annotations
        validate_prefixed_permitted_annotations("authn-k8s/")
        validate_prefixed_permitted_annotations("authn-k8s/#{@service_id}/")
      end

      def validate_prefixed_permitted_annotations prefix
        @logger.debug(LogMessages::Authentication::ValidatingAnnotationsWithPrefix.new(prefix))

        prefixed_k8s_annotations(prefix).each do |annotation|
          annotation_name = annotation[:name]
          next if prefixed_permitted_annotations(prefix).include?(annotation_name)
          raise Errors::Authentication::Constraints::ConstraintNotSupported.new(annotation_name.gsub(prefix, ""), K8S_RESOURCE_TYPES)
        end
      end

      def prefixed_k8s_annotations prefix
        @host_annotations.select do |a|
          annotation_name = a.values[:name]

          # Calculate the granularity level of the annotation.
          # For example, the annotation "authn-k8s/namespace" is in the general
          # level, and applies to every host that tries to authenticate with the
          # k8s authenticator, regardless of the service id.
          # The annotation "authn-k8s/#{@service_id}/namespace" is on the
          # service-id level, and applies only to hosts trying to authenticate
          # with the authenticator "authn-k8s/#{@service_id}".
          annotation_granularity_level = annotation_name.split('/').length
          prefix_granularity_level     = prefix.split('/').length

          annotation_name.start_with?(prefix) &&
            # Verify we take only annotations from the same level.
            annotation_granularity_level == prefix_granularity_level + 1
        end
      end

      def prefixed_permitted_annotations prefix
        permitted_annotations.map { |k| "#{prefix}#{k}" }
      end

      def permitted_annotations
        @permitted_annotations ||= K8S_RESOURCE_TYPES | [ AUTHENTICATION_CONTAINER_NAME_ANNOTATION ]
      end

      def validate_host_id
        @logger.debug(LogMessages::Authentication::AuthnK8s::ValidatingHostId.new(@host_id))

        valid_host_id = @host_id.length == 3
        raise Errors::Authentication::AuthnK8s::InvalidHostId, @host_id unless valid_host_id

        return if host_id_namespace_scoped?

        resource_type       = @host_id[-2]
        unless underscored_k8s_resource_types.include?(resource_type)
          raise Errors::Authentication::Constraints::ConstraintNotSupported.new(resource_type, underscored_k8s_resource_types)
        end
      end

      def host_id_namespace_scoped?
        @host_id[-2] == '*' && @host_id[-1] == '*'
      end

      def validate_required_constraints_exist
        validate_resource_constraint_exists "namespace"
      end

      def validate_resource_constraint_exists resource_type
        resource = @resources.find { |a| a.type == resource_type }
        raise Errors::Authentication::Constraints::RoleMissingConstraints, resource_type unless resource
      end

      # Validates that the resource restrictions don't include logical resource constraint
      # combinations (e.g deployment & deploymentConfig)
      def validate_constraint_combinations
        identifiers = %w(deployment deployment-config stateful-set)

        identifiers_constraints = @resources.map(&:type) & identifiers
        unless identifiers_constraints.length <= 1
          raise Errors::Authentication::Constraints::IllegalConstraintCombinations, identifiers_constraints
        end
      end

      def resource_from_id resource_type
        return @host_id[-3] if resource_type == "namespace"
        @host_id[-2] == resource_type ? @host_id[-1] : nil
      end

      def underscored_k8s_resource_types
        @underscored_k8s_resource_types ||= K8S_RESOURCE_TYPES.map { |resource_type| underscored_k8s_resource_type(resource_type) }
      end

      def underscored_k8s_resource_type resource_type
        resource_type.tr('-', '_')
      end
    end
  end
end
