Before('@skip') do
  skip_this_scenario
end

Before('@k8s_skip') do
  skip_this_scenario if ENV['PLATFORM'] == 'kubernetes' || ENV['PLATFORM'] == 'openshift'
end

Before do
  if ENV['CONJUR_APPLIANCE_URL'].nil? || ENV['CONJUR_APPLIANCE_URL'].empty?
    ENV['CONJUR_APPLIANCE_URL'] = "http://conjur#{ENV['TEST_ENV_NUMBER']}"
    puts "SET CONJUR_APPLIANCE_URL #{File.dirname(__FILE__)}/#{File.basename(__FILE__)}"
  else
    puts "NOT EMPTY CONJUR_APPLIANCE_URL"
  end
  if ENV['DATABASE_URL'].nil? || ENV['DATABASE_URL'].empty?
    ENV['DATABASE_URL'] = "postgres://postgres@pg#{ENV['TEST_ENV_NUMBER']}/postgres"
    puts "SET DATABASE_URL #{File.dirname(__FILE__)}/#{File.basename(__FILE__)}"
  else
    puts "NOT EMPTY DATABASE_URL"
  end
  if ENV['CONJUR_AUTHN_API_KEY'].nil? || ENV['CONJUR_AUTHN_API_KEY'].empty?
    api_string = "CONJUR_AUTHN_API_KEY#{ENV['TEST_ENV_NUMBER']}"
    ENV['CONJUR_AUTHN_API_KEY'] = ENV[api_string]
    puts "SET CONJUR_AUTHN_API_KEY #{File.dirname(__FILE__)}/#{File.basename(__FILE__)}"
  else
    puts "NOT EMPTY CONJUR_AUTHN_API_KEY"
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
