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

      Err = Errors::Authentication::AuthnK8s

      class << self
        # Gets a resolver class for a resource type.
        def for_resource resource_type
          const_get(resource_type.classify)
        rescue NameError
          raise Err::UnknownK8sResourceType, resource_type.inspect
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
        # Verifies that a condition, specified by a block, is truthy.
        #
        # @exception ValidationError with the specified +message+ is raised if the
        # +block+ returns a falsey value.
        def verify message, &block
          yield.tap do |result|
            raise Err::ValidationError, message unless result
          end
        end

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
        # @exception ValidationError if the +pod+ does not belong to the resource object.
        def validate_pod
          raise "validate_pod is not implemented"
        end
      end

      # Tests whether the Pod's ReplicaSet belongs to the Deployment.
      class Deployment < Base
        def validate_pod
          replica_set_ref = verify "Pod #{pod_name} does not belong to a ReplicaSet (or Deployment)" do
            pod_owner_refs &&
              pod_owner_refs.find{|ref| ref.kind == "ReplicaSet"}
          end
          
          replica_set = k8s_object_lookup.find_object_by_name "replica_set", replica_set_ref.name, namespace

          deployment_ref = verify "Pod #{pod_name} does not belong to a Deployment" do
            replica_set.metadata.ownerReferences &&
              replica_set.metadata.ownerReferences.find{|ref| ref.kind == "Deployment"}
          end

          deployment = k8s_object_lookup.find_object_by_name "deployment", deployment_ref.name, namespace

          verify "Pod #{pod_name} Deployment is #{deployment.metadata.name.inspect}, not #{self.name.inspect}" do
            self.name == deployment.metadata.name
          end
        end
      end

      class DeploymentConfig < Base
        def validate_pod
          replication_resource_ref = verify "Pod #{pod_name} does not belong to a ReplicationController (or DeploymentConfig)" do
            pod_owner_refs &&
              pod_owner_refs.find{|ref| ref.kind == "Replicationresource"}
          end
          
          replication_resource = k8s_object_lookup.find_object_by_name "replication_resource", replication_resource_ref.name, namespace

          deployment_config_ref = verify "Pod #{pod_name} does not belong to a DeploymentConfig" do
            replication_resource.metadata.ownerReferences &&
              replication_resource.metadata.ownerReferences.find{|ref| ref.kind == "DeploymentConfig"}
          end

          deployment_config = k8s_object_lookup.find_object_by_name "deployment_config", deployment_config_ref.name, namespace

          verify "Pod #{pod_name} DeploymentConfig is #{deployment_config.metadata.name.inspect}, not #{self.name.inspect}" do
            self.name == deployment_config.metadata.name
          end
        end
      end

      class ReplicaSet < Base
        def validate_pod
          replica_set_ref = verify "Pod #{pod_name} does not belong to a ReplicaSet" do
            pod_owner_refs &&
              pod_owner_refs.find{|ref| ref.kind == "ReplicaSet"}
          end

          replica_set = k8s_object_lookup.find_object_by_name "replica_set", replica_set_ref.name, namespace

          verify "Pod #{pod_name} ReplicaSet is #{replica_set.metadata.name.inspect}, not #{self.name.inspect}" do
            self.name == replica_set.metadata.name
          end
        end
      end

      class ServiceAccount < Base
        def validate_pod
          verify "Pod #{pod_name} assigned ServiceAccount #{pod.spec.serviceAccountName.inspect}, not #{self.name.inspect}" do
            self.name == pod.spec.serviceAccountName
          end
        end
      end

      class StatefulSet < Base
        def validate_pod
          stateful_set_ref = verify "Pod #{pod_name} does not belong to a StatefulSet" do
            pod_owner_refs &&
              pod_owner_refs.find{|ref| ref.kind == "StatefulSet"}
          end

          stateful_set = k8s_object_lookup.find_object_by_name "stateful_set", stateful_set_ref.name, namespace      

          verify "Pod #{pod_name} StatefulSet name is #{stateful_set.metadata.name.inspect}, not #{self.name.inspect}" do
            self.name == stateful_set.metadata.name
          end
        end
      end

      class Pod < Base
        # The pod is always a member of itself.
        def validate_pod
          verify "Pod #{pod_name} is not #{self.name.inspect}" do
            self.name == pod.metadata.name
          end
        end
      end
    end
  end
end
