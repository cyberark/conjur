Before('@skip') do
  skip_this_scenario
end

Before('@k8s_skip') do
  skip_this_scenario if ENV['PLATFORM'] == 'kubernetes' || ENV['PLATFORM'] == 'openshift'
end

Before do
  parallel_cuke_vars = Hash.new
  parallel_cuke_vars['CONJUR_APPLIANCE_URL'] = "https://nginx#{ENV['TEST_ENV_NUMBER']}"
  parallel_cuke_vars['DATABASE_URL'] = "postgres://postgres@postgres#{ENV['TEST_ENV_NUMBER']}:5432/postgres"
  parallel_cuke_vars['CONJUR_AUTHN_API_KEY'] = ENV["CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"]

  parallel_cuke_vars.each do |key, value|
    if ENV[key].nil? || ENV[key].empty?
      ENV[key] = value
    end
  end

  puts "********"
  puts "RUNNING ON PROCESS #{ENV['TEST_ENV_NUMBER']}:"
  puts "CONJUR_URL: #{ENV['CONJUR_APPLIANCE_URL']}"
  puts "DATABASE: #{ENV['DATABASE_URL']}"
  puts "API KEY: #{ENV['CONJUR_AUTHN_API_KEY']}"
  puts "********"
  # Erase the certificate and cert injection logs from each container.
  kube_client.get_pods(namespace: namespace).select{|p| p.metadata.namespace == namespace}.each do |pod|
    next unless (ready_status = pod.status.conditions.find { |c| c.type == "Ready" })
    next unless ready_status.status == "True"
    next unless pod.metadata.name =~ /inventory-/

    pod.spec.containers.each do |container|
      next unless container.name == "authenticator"

      cmds = %w[rm -rf /etc/conjur/ssl/* && rm -rf /tmp/*]
      puts "Running command '#{cmds.join(' ')}' container #{container.name} in pod #{pod.metadata.name}"
      Authentication::AuthnK8s::ExecuteCommandInContainer.new.call(
        k8s_object_lookup: Authentication::AuthnK8s::K8sObjectLookup.new,
        pod_namespace: pod.metadata.namespace,
        pod_name: pod.metadata.name,
        container: container.name,
        cmds: cmds,
        body: "",
        stdin: false
      )
    end
  end
end
