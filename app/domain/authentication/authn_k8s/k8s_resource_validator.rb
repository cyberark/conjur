module Authentication
  module AuthnK8s

    # This class can validate that a k8s resource exists, and that the
    # initialized 'pod' belongs to it. It uses to pod's namespace to look for
    # the given resource name.
    # It meant to be created once per k8s authentication request, given the
    # relevant context, and reused for each k8s resource validation needed.
    # Because it is instantiated for each request, it cannot be replaced with
    # CommandClass that needs constant dependencies.
    class K8sResourceValidator
      def initialize(k8s_object_lookup:, pod:, logger: Rails.logger)
        @k8s_object_lookup = k8s_object_lookup
        @pod = pod
        @logger = logger
      end

      def valid_resource?(type:, name:)
        @logger.debug(LogMessages::Authentication::AuthnK8s::ValidatingK8sResource.new(type, name))

        k8s_resource = retrieve_k8s_resource(type, name)
        validate(k8s_resource, type, name)

        @logger.debug(LogMessages::Authentication::AuthnK8s::ValidatedK8sResource.new(type, name))
      end

      # Validates label selector and creates a hash
      # In the spirit of https://github.com/kubernetes/apimachinery/blob/master/pkg/labels/selector.go
      def valid_namespace?(label_selector:)
        @logger.debug(LogMessages::Authentication::AuthnK8s::ValidatingK8sResourceLabel.new('namespace', namespace, label_selector))

        if label_selector.length == 0
          raise Errors::Authentication::AuthnK8s::InvalidLabelSelector.new(label_selector)
        end
        label_selector_hash = label_selector
          .split(",")
          .map{ |kv_pair|
            kv_pair = kv_pair.split(/={1,2}/, 2)

            invalid ||= kv_pair.length != 2
            invalid ||= kv_pair[0].include?("!")

            if (invalid)
              raise Errors::Authentication::AuthnK8s::InvalidLabelSelector.new(label_selector)
            end

            kv_pair[0] = kv_pair[0].to_sym
            kv_pair
          }
          .to_h

        # Fetch namespace labels
        # TODO: refactor this to have a generic label fetching method in @k8s_object_lookup
        labels_hash = @k8s_object_lookup.namespace_labels_hash(namespace)

        # Validates label selector hash against labels hash
        unless label_selector_hash.all? { |k, v| labels_hash[k] == v }
          raise Errors::Authentication::AuthnK8s::LabelSelectorMismatch.new('namespace', namespace, label_selector)
        end

        @logger.debug(LogMessages::Authentication::AuthnK8s::ValidatedK8sResourceLabel.new('namespace', namespace, label_selector))
        return true
      end

      private

      def retrieve_k8s_resource(type, name)
        @k8s_object_lookup.find_object_by_name(
          type,
          name,
          namespace
        )
      end

      def validate(k8s_resource, type, name)
        unless k8s_resource
          raise Errors::Authentication::AuthnK8s::K8sResourceNotFound.new(type, name, namespace)
        end

        K8sResolver
          .for_resource(type)
          .new(
            k8s_resource,
            @pod,
            @k8s_object_lookup
          )
          .validate_pod
      end

      def namespace
        @namespace ||= @pod.metadata.namespace
      end
    end
  end
end
