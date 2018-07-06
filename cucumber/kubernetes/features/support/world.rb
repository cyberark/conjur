module AuthnK8sWorld
  def test_namespace
    ENV["CONJUR_AUTHN_K8S_TEST_NAMESPACE"]
  end

  alias namespace test_namespace

  def kubectl_client
    Authentication::AuthnK8s::K8sObjectLookup.kubectl_client
  end

  def authn_k8s_host
    "#{Conjur.configuration.appliance_url}/authn-k8s/minikube"
  end

  def last_json
    last_response.body
  end

  def substitute pattern
    pattern.gsub! "@pod_ip@", @pod.status.podIP if @pod
    pattern.gsub! "@pod_ip_dashes@", @pod.status.podIP.gsub('.', '-') if @pod
    pattern.gsub! "@namespace@", @pod.metadata.namespace if @pod
    pattern
  end

  # get pod cert
  def pod_certificate
    exec = KubectlExec.new @pod, container: "authenticator"
    response = nil

    retries = 3
    count = 0

    while response.nil? || (!response[:error].empty? && count < retries)
      response = exec.exec [ "cat", "/etc/conjur/ssl/client.pem" ]
      sleep 2
      count += 1
    end

    if response[:error] && response[:error].join =~ /command terminated with non-zero exit code/
      $stderr.puts "Unable to retrieve client certificate for pod #{@pod.metadata.name.inspect}"
    else
      response[:stdout].join
    end
  end

  # Find pod matching label selector.
  def find_matching_pod label_selector
    @pod = pod = Authentication::AuthnK8s::K8sObjectLookup.find_pods_by_label_selector_in_namespace(label_selector, namespace).first
    raise "No pod found matching label selector: #{label_selector.inspect}" unless pod
    "found"
  end

  # Find a valid request IP for the given object.
  def detect_request_ip objectid
    expect(objectid).to match(/^([\w-])+\/([\w-])+$/)
    controller_type, id = objectid.split('/')
    controller = Authentication::AuthnK8s::K8sObjectLookup.find_object_by_name controller_type, id, namespace
    raise "#{objectid.inspect} not found" unless controller

    @pod = pod = kubectl_client.get_pods(namespace: namespace).find do |pod|
      resolver = K8sResolver.for_controller(controller_type).new(controller, pod)
      begin
        resolver.validate_pod
        true
      rescue K8sResolver::ValidationError
        false
      end
    end

    if pod
      $stderr.puts "Using Pod #{pod.metadata.name} for objectid #{objectid}"
      pod.status.podIP
    else
      $stderr.puts "No pod found for objectid #{objectid}"
      "192.0.2.0"
    end
  end
end

World(Rack::Test::Methods, AuthnK8sWorld)
