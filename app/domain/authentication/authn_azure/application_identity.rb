module Authentication
  module AuthnAzure

    Log = LogMessages::Authentication
    Err = Errors::Authentication::AuthnAzure
    # Possible Errors Raised: MissingNamespaceConstraint, IllegalConstraintCombinations,
    # ScopeNotSupported, InvalidHostId

    # This class defines an application identity of a given conjur host.
    # The constructor initializes an ApplicationIdentity object and validates that
    # it is configured correctly.
    # The difference between the validation in this constructor and
    # the validation in ValidateApplicationIdentity is that here we validate that
    # the application identity is configured correctly, and thus is a valid application
    # identity. In ValidateApplicationIdentity we validate that the defined application
    # identity is actually the correct one in kubernetes.
    # For example, an application identity `some-namepsace/blah/some-value` is not
    # valid and will fail the validation here. However, an application identity
    # `some-namespace/service-account/some-value` is a valid application identity
    # and will pass the validation here. If the host is actually running from
    # a pod with service account `some-other-value` then it will fail the
    # validation of ValidateApplicationIdentity
    class ApplicationIdentity

      def initialize(host_id:, host_annotations:)
        @host_id          = host_id
        @host_annotations = host_annotations
        @service_id       = service_id

        validate
      end

      # add validator to check resource group and subscription id are present
      def constraints
        @constraints ||= {
            subscription_id:          constraint_value("subscription-id"),
            resource_group:           constraint_value("resource-group"),
            user_assigned_identity:   constraint_value("user-assigned-identity"),
            system_assigned_identity: constraint_value("system-assigned-identity"),
        }.compact
      end

      private

      # Validates that the application identity is defined correctly
      def validate
        # Check if annotations present are part of the permitted annotations for authn-azure
        validate_permitted_annotations

        # validate that a constraint exists on the required annotations
        raise Err::MissingAnnotationConstraint.new(constraints.subscription_id) unless constraint_from_annotation constraints.has_key? "subscription_id"
        raise Err::MissingAnnotationConstraint.new(constraints.resource_group) unless constraint_from_annotation constraints.has_key? "resource_group"

        validate_constraint_combinations
      end

      # Validates that the required annotations (subscription_id and resource_group) exist in annotations
      def constraint_from_annotation constraint_name
        annotation_value("authn-azure/#{@service_id}/#{constraint_name}") ||
            annotation_value("authn-azure/#{constraint_name}")
      end

      def annotation_value name
        annotation = @host_annotations.find { |a| a.values[:name] == name }

        # return the value of the annotation if it exists, nil otherwise
        if annotation
          Rails.logger.debug(Log::RetrievedAnnotationValue.new(name))
          annotation[:value]
        end
      end

      # Validates that the application identity doesn't include logical constraint
      # combinations (e.g user_assigned_identity & system_assigned_identity)
      # & TODO: .key & = union
      def validate_constraint_combinations
        controllers = %i(user_assigned_identity system_assigned_identity)

        controller_constraints = constraints.keys & controllers
        raise Err::IllegalConstraintCombinations, controller_constraints unless controller_constraints.length <= 1
      end

      def constraint_value constraint_name
        constraint_from_annotation(constraint_name)
      end

      def validate_permitted_annotations
        validate_prefixed_permitted_annotations("authn-azure/")
        validate_prefixed_permitted_annotations("authn-azure/#{@service_id}/")
      end

      def prefixed_k8s_annotations prefix
        @host_annotations.select do |a|
          annotation_name = a.values[:name]

          annotation_name.start_with?(prefix) &&
              # Verify we take only annotations from the same level
              annotation_name.split('/').length == prefix.split('/').length + 1
        end
      end

      # adds 'authn-azure prefix' to all permitted constraints
      def prefixed_permitted_annotations prefix
        permitted_annotations.map { |k| "#{prefix}#{k}" }
      end

      # takes all annotations with authn-azure and checks if annotations is part of the permitted list
      def validate_prefixed_permitted_annotations prefix
        Rails.logger.debug(Log::ValidatingAnnotationsWithPrefix.new(prefix))

        prefixed_k8s_annotations(prefix).each do |annotation|
          annotation_name = annotation[:name]
          next if prefixed_permitted_annotations(prefix).include?(annotation_name)
          raise Err::ScopeNotSupported.new(annotation_name.gsub(prefix, ""), annotation_type_constraints)
        end
      end
    end
  end
end
