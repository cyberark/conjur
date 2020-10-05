Before('@skip') do
  skip_this_scenario
end

Before('@k8s_skip') do
  skip_this_scenario if ENV['PLATFORM'] == 'kubernetes'
end

Before do
  # Erase the certificates and keys from each container.
  kube_client.get_pods(namespace: namespace).select{|p| p.metadata.namespace == namespace}.each do |pod|
    next unless (ready_status = pod.status.conditions.find { |c| c.type == "Ready" })
    next unless ready_status.status == "True"
    next unless pod.metadata.name =~ /inventory\-/

    exec = Authentication::AuthnK8s::KubeExec.new

    pod.spec.containers.each do |container|
      next unless container.name == "authenticator"

      exec.execute(
        k8s_object_lookup: Authentication::AuthnK8s::K8sObjectLookup.new,
        pod_namespace: pod.metadata.namespace,
        pod_name: pod.metadata.name,
        container: container.name,
        cmds: %w(rm -rf /etc/conjur/ssl/*)
      )
    end
  end
end
