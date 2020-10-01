module AuthnK8sWorld
  def test_namespace
    ENV["CONJUR_AUTHN_K8S_TEST_NAMESPACE"]
  end

  alias namespace test_namespace

  def k8s_object_lookup
    @k8s_object_lookup ||= Authentication::AuthnK8s::K8sObjectLookup.new
  end

  def kube_client
    k8s_object_lookup.kube_client
  end

  def authn_k8s_host
    "#{Conjur.configuration.appliance_url}/authn-k8s/minikube"
  end

  def last_json
    last_response.body
  end

  def substitute! pattern
    pattern.gsub! "@pod_ip@", @pod.status.podIP if @pod
    pattern.gsub! "@pod_ip_dashes@", @pod.status.podIP.gsub('.', '-') if @pod
    pattern.gsub! "@namespace@", @pod.metadata.namespace if @pod
    pattern
  end

  def kube_exec
    Authentication::AuthnK8s::KubeExec.new
  end

  def print_result_errors response
    if response
      $stderr.puts "ERROR: STDOUT: '#{response[:stdout]}'"
      $stderr.puts "ERROR: STDERR: '#{response[:error]}'"
    else
      $stderr.puts "ERROR: Response was nil!"
    end
  end

  # get pod cert
  def pod_certificate
    response = nil
    retries = 10
    count = 0
    success = false

    pod_metadata = @pod.metadata
    while count < retries
      puts "Waiting for client cert to be available (Attempt #{count + 1} of #{retries})"

      pod_metadata = @pod.metadata
      response = kube_exec.execute(
        k8s_object_lookup: Authentication::AuthnK8s::K8sObjectLookup.new,
        pod_namespace: pod_metadata.namespace,
        pod_name: pod_metadata.name,
        cmds: [ "cat", "/etc/conjur/ssl/client.pem" ]
      )

      if !response.nil? && response[:error].empty? && !response[:stdout].to_s.strip.empty?
        success = true
        break
      end

      print_result_errors response
      sleep 2
      count += 1
    end

    if !success
      puts "ERROR: Unable to retrieve client certificate for pod #{@pod.metadata.name.inspect}, " \
           "printing logs from the container..."
      get_cert_injection_logs_response = kube_exec.execute(
        k8s_object_lookup: Authentication::AuthnK8s::K8sObjectLookup.new,
        pod_namespace: pod_metadata.namespace,
        pod_name: pod_metadata.name,
        cmds: [ "cat", "/tmp/conjur_set_file_content.log" ]
      )

      if !get_cert_injection_logs_response.nil? &&
          get_cert_injection_logs_response[:error].empty? &&
          !get_cert_injection_logs_response[:stdout].to_s.strip.empty?
        puts get_cert_injection_logs_response[:stdout].join.to_s
      else
        puts "Failed to retrieve cert injection logs from container"
      end

      $stderr.puts "ERROR: Unable to retrieve client certificate for pod #{@pod.metadata.name.inspect}"
    else
      response[:stdout].join
    end
  end

  # Find pod matching label selector.
  def find_matching_pod(label_selector)
    @pod = k8s_object_lookup
      .pods_by_label(label_selector, namespace)
      .first

    err = "No pod found matching label selector: #{label_selector.inspect}"
    raise err unless @pod
    "found"
  end

  # Find a valid request IP for the given object.
  def detect_request_ip objectid
    expect(objectid).to match(/^([\w-])+\/([\w-])+$/)
    controller_type, id = objectid.split('/')
    controller = k8s_object_lookup.find_object_by_name controller_type, id, namespace
    raise "#{objectid.inspect} not found" unless controller

    @pod = pod = kube_client.get_pods(namespace: namespace).find do |pod|
      resolver = Authentication::AuthnK8s::K8sResolver.for_resource(controller_type).new(controller, pod, k8s_object_lookup)
      begin
        resolver.validate_pod
        true
      rescue Errors::Authentication::AuthnK8s::PodNameMismatchError,
             Errors::Authentication::AuthnK8s::PodRelationMismatchError,
             Errors::Authentication::AuthnK8s::PodMissingRelationError
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

  def gen_csr(id, signing_key, altnames)
    # create certificate subject
    common_name = id.tr('/', '.')
    subject = OpenSSL::X509::Name.new(
      [
        ['CN', common_name],
        # ['O', id],
        # ['C', id],
        # ['ST', id],
        # ['L', id]
      ]
    )

    # create CSR
    csr = OpenSSL::X509::Request.new
    csr.version = 0
    csr.subject = subject
    csr.public_key = signing_key.public_key

    # prepare SAN extension
    extensions = [
      OpenSSL::X509::ExtensionFactory.new.create_extension('subjectAltName', altnames.join(','))
    ]

    # add SAN extension to the CSR
    attribute_values = OpenSSL::ASN1::Set [OpenSSL::ASN1::Sequence(extensions)]
    [
      OpenSSL::X509::Attribute.new('extReq', attribute_values),
      OpenSSL::X509::Attribute.new('msExtReq', attribute_values)
    ].each do |attribute|
      csr.add_attribute attribute
    end

    # sign CSR with the signing key
    csr.sign signing_key, OpenSSL::Digest::SHA256.new
  end
end

World(Rack::Test::Methods, AuthnK8sWorld)
