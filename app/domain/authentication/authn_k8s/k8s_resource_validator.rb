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

      def valid_namespace?(label_selector:)
        # APPROACH
        # 
        # namespaces = @k8s_object_lookup.namespace_by_label(namespace, label_selector)
        # condition = namespaces.any?

        # APPROACH
        namespace_object = @k8s_object_lookup.namespace_by_name(namespace)

        # in the spirit of https://github.com/kubernetes/apimachinery/blob/master/pkg/labels/selector.go
        labels_h = namespace_object.metadata.labels.to_h
        label_selector_h = label_selector
          .split(",")
          .map{ |kv_pair| kv_pair = kv_pair.split("="); kv_pair[0] = kv_pair[0].to_sym; kv_pair }
          .to_h
        condition = label_selector_h.all? { |k, v| labels_h[k] == v }

        unless condition
          raise Errors::Authentication::AuthnK8s::NamespaceLabelSelectorMismatch.new(namespace, label_selector)
        end
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
