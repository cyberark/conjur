# NOTE: This file has has not been refactored yet.  In particular, the name
# K8sResolver is too ambiguous, and per the explanation below should probably
# be changed to `ValidateK8sResource`. Since its used only for validation, we
# could use that name, inject the K8sObjectLookup dependency, and give it a
# `.call(resource, object, pod)` method.
#
# A resolver looks up a logical application in the Kubernetes object store.
# A logical application is a K8s resource such as a Deployment or StatefulSet.
# When a request arrives at authn-k8s, the request IP identifies a Pod, and the
# "username" request parameter identifies the Conjur role. The Conjur role 
# is named according to the scheme "<namespace>/<resource-name>/<object-name>". For
# example, the role Id of the "myapp" Deployment in the "default" namespace 
# would end with "/default/deployment/myapp".
#
# The K8sResolver determines if the Pod, identified by the request Id, is a 
# member of the Conjur role (= Kubernetes resource) that it wants to authenticate as.
module Authentication
  module AuthnK8s

    module K8sResolver

      class << self
        # Gets a resolver class for a resource type.
        def for_resource resource_type
          const_get(resource_type.classify)
        rescue NameError
          raise Errors::Authentication::AuthnK8s::UnknownK8sResourceType,
                resource_type.inspect
        end
      end

      # Determines if a Kubernetes resource exists and contains a specified Pod.
      #
      # Subclasses implement the resolution logic, which inspects the Kubernetes metadata
      # of the resource and the Pod.
      #
      # * +resource+ the resource API object (e.g. a Deployment)
      # * +pod+ the Pod API object.
      Base = Struct.new(:resource, :pod, :k8s_object_lookup) do
        def name
          resource.metadata.name
        end

        def namespace
          resource.metadata.namespace
        end

        def pod_name
          pod.metadata.name.inspect
        end

        def pod_owner_refs
          pod.metadata.ownerReferences
        end

        # Validates that the +pod+ belongs to the resource object.
        #
        # @exception PodNameMismatchError,PodRelationMismatchError, PodMissingRelationError if the +pod+ does not
        # belong to the resource object.
        def validate_pod
          raise "validate_pod is not implemented"
        end
      end

      # Tests whether the Pod's ReplicaSet belongs to the Deployment.
      class Deployment < Base
        def validate_pod
          replica_set_ref = pod_owner_refs&.find { |ref| ref.kind == "ReplicaSet" }
          unless replica_set_ref
            raise Errors::Authentication::AuthnK8s::PodMissingRelationError.new(
              pod_name,
              'ReplicaSet'
            )
          end

          replica_set = k8s_object_lookup.find_object_by_name "replica_set", replica_set_ref.name, namespace
          replica_set_owner_refs = replica_set.metadata.ownerReferences

          deployment_ref = replica_set_owner_refs&.find { |ref| ref.kind == "Deployment" }
          unless deployment_ref
            raise Errors::Authentication::AuthnK8s::PodMissingRelationError.new(
              pod_name,
              'Deployment'
            )
          end

          deployment = k8s_object_lookup.find_object_by_name "deployment", deployment_ref.name, namespace

          unless self.name == deployment.metadata.name
            raise Errors::Authentication::AuthnK8s::PodRelationMismatchError.new(
              pod_name,
              'Deployment',
              deployment.metadata.name.inspect,
              self.name.inspect
            )
          end
        end
      end

      class DeploymentConfig < Base
        def validate_pod
          replication_resource_ref = pod_owner_refs&.find { |ref| ref.kind == "Replicationresource" }
          unless replication_resource_ref
            raise Errors::Authentication::AuthnK8s::PodMissingRelationError.new(
              pod_name,
              'ReplicationController'
            )
          end

          replication_resource = k8s_object_lookup.find_object_by_name(
            "replication_resource",
            replication_resource_ref.name,
            namespace
          )

          replication_resource_owner_refs = replication_resource.metadata.ownerReferences

          deployment_config_ref = replication_resource_owner_refs&.find { |ref| ref.kind == "DeploymentConfig" }

          unless deployment_config_ref
            raise Errors::Authentication::AuthnK8s::PodMissingRelationError.new(
              pod_name,
              'DeploymentConfig'
            )
          end

          deployment_config = k8s_object_lookup.find_object_by_name "deployment_config",
            deployment_config_ref.name, namespace

          unless self.name == deployment_config.metadata.name
            raise Errors::Authentication::AuthnK8s::PodRelationMismatchError.new(
              pod_name,
              'DeploymentConfig',
              deployment_config.metadata.name.inspect,
              self.name.inspect
            )
          end
        end
      end

      class ReplicaSet < Base
        def validate_pod
          replica_set_ref = pod_owner_refs&.find { |ref| ref.kind == "ReplicaSet" }
          unless replica_set_ref
            raise Errors::Authentication::AuthnK8s::PodMissingRelationError.new(
              pod_name,
              'ReplicaSet'
            )
          end

          replica_set = k8s_object_lookup.find_object_by_name "replica_set", replica_set_ref.name, namespace

          unless self.name == replica_set.metadata.name
            raise Errors::Authentication::AuthnK8s::PodRelationMismatchError.new(
              pod_name,
              'ReplicaSet',
              replica_set.metadata.name.inspect,
              self.name.inspect
            )
          end
        end
      end

      class ServiceAccount < Base
        def validate_pod
          unless self.name == pod.spec.serviceAccountName
            raise Errors::Authentication::AuthnK8s::PodRelationMismatchError.new(
              pod_name,
              'ServiceAccount',
              pod.spec.serviceAccountName.inspect,
              self.name.inspect
            )
          end
        end
      end

      class StatefulSet < Base
        def validate_pod
          stateful_set_ref = pod_owner_refs&.find { |ref| ref.kind == "StatefulSet" }
          unless stateful_set_ref
            raise Errors::Authentication::AuthnK8s::PodMissingRelationError.new(
              pod_name,
              'StatefulSet'
            )
          end

          stateful_set = k8s_object_lookup.find_object_by_name "stateful_set", stateful_set_ref.name, namespace

          unless self.name == stateful_set.metadata.name
            raise Errors::Authentication::AuthnK8s::PodRelationMismatchError.new(
              pod_name,
              'StatefulSetName',
              stateful_set.metadata.name.inspect,
              self.name.inspect
            )
          end
        end
      end

      class Pod < Base
        # The pod is always a member of itself.
        def validate_pod
          unless self.name == pod.metadata.name
            raise Errors::Authentication::AuthnK8s::PodNameMismatchError.new(
              pod_name,
              self.name.inspect
            )
          end
        end
      end
    end
  end
end
