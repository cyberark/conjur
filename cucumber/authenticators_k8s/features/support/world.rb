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
    pattern.gsub!("@pod_ip@", @pod.status.podIP) if @pod
    pattern.gsub!("@pod_ip_dashes@", @pod.status.podIP.gsub('.', '-')) if @pod
    pattern.gsub!("@namespace@", @pod.metadata.namespace) if @pod
    pattern
  end

  def print_result_errors response
    if response
      $stderr.puts("ERROR: STDOUT: '#{response[:stdout]}'")
      $stderr.puts("ERROR: STDERR: '#{response[:error]}'")
    else
      $stderr.puts("ERROR: Response was nil!")
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
      puts("Waiting for client cert to be available (Attempt #{count + 1} of #{retries})")

      pod_metadata = @pod.metadata
      begin
        response = Authentication::AuthnK8s::ExecuteCommandInContainer.new.call(
          k8s_object_lookup: Authentication::AuthnK8s::K8sObjectLookup.new,
          pod_namespace: pod_metadata.namespace,
          pod_name: pod_metadata.name,
          container: "authenticator",
          cmds: %w[cat /etc/conjur/ssl/client.pem],
          body: "",
          stdin: false
        )

        if !response.nil? && response[:error].empty? && !response[:stdout].to_s.strip.empty?
          puts("Retrieved client cert from container")
          success = true
          break
        end

        print_result_errors(response)
      rescue Errors::Authentication::AuthnK8s::ExecCommandError => e
        # There are two expected errors, which we avoid printing so as not to
        # pollute the logs:
        #   1. Container not up yet (error contains
        #      'cat /etc/conjur/ssl/client.pem')
        #   2. File not in container yet (contains 'Error executing in Docker
        #      Container: 1')
        # But we still always retry, so that this code won't be fragile.
        is_expected_err =
          e.inspect.include?("cat /etc/conjur/ssl/client.pem") ||
          e.inspect.include?("Error executing in Docker Container: 1")
        unless is_expected_err
          puts("Failed to retrieve client cert with error: #{e.inspect}")
          e.backtrace.each { |line| puts(line) }
        end
      ensure
        sleep(2)
        count += 1
      end
    end

    return response[:stdout].join if success

    puts("ERROR: Unable to retrieve client certificate for pod #{@pod.metadata.name.inspect}, " \
           "printing logs from the container...")
    begin
      get_cert_injection_logs_response = Authentication::AuthnK8s::ExecuteCommandInContainer.new.call(
        k8s_object_lookup: Authentication::AuthnK8s::K8sObjectLookup.new,
        pod_namespace: pod_metadata.namespace,
        pod_name: pod_metadata.name,
        container: "authenticator",
        cmds: %w[cat /tmp/conjur_copy_text_output.log],
        body: "",
        stdin: false
      )

      if !get_cert_injection_logs_response.nil? &&
          get_cert_injection_logs_response[:error].empty? &&
          !get_cert_injection_logs_response[:stdout].to_s.strip.empty?
        @cert_injection_logs = get_cert_injection_logs_response[:stdout].join.to_s
        puts("Retrieved cert injection logs from container:\n #{@cert_injection_logs}")
      else
        puts("Failed to retrieve cert injection logs from container")
      end
    rescue Errors::Authentication::AuthnK8s::ExecCommandError => e
      puts("Failed to retrieve client cert with error: #{e.inspect}")
      e.backtrace.each do |line|
        puts(line)
      end
    end

    $stderr.puts("ERROR: Unable to retrieve client certificate for pod #{@pod.metadata.name.inspect}")
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
    controller = k8s_object_lookup.find_object_by_name(controller_type, id, namespace)
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
      $stderr.puts("Using Pod #{pod.metadata.name} for objectid #{objectid}")
      pod.status.podIP
    else
      $stderr.puts("No pod found for objectid #{objectid}")
      "192.0.2.0"
    end
  end

  def gen_csr(id, signing_key, altnames)
    # create certificate subject
    common_name = id.tr('/', '.')
    subject = OpenSSL::X509::Name.new(
      [
        ['CN', common_name]
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
    attribute_values = OpenSSL::ASN1::Set([OpenSSL::ASN1::Sequence(extensions)])
    [
      OpenSSL::X509::Attribute.new('extReq', attribute_values),
      OpenSSL::X509::Attribute.new('msExtReq', attribute_values)
    ].each do |attribute|
      csr.add_attribute(attribute)
    end

    # sign CSR with the signing key
    csr.sign(signing_key, OpenSSL::Digest.new('SHA256'))
  end

  def admin_api_key
    # This file is written when the environment is provisioned in
    # test_gke_entrypoint.sh
    @admin_api_key ||= File.read('/run/conjur_api_key').strip
  end

  def admin_access_token
    RestClient::Resource.new(
      "#{Conjur.configuration.appliance_url}/authn/cucumber/admin/authenticate",
      ssl_ca_file: './nginx.crt',
      headers: {
        "Accept-Encoding" => "base64"
      }
    ).post(admin_api_key)
  end
end

World(Rack::Test::Methods, AuthnK8sWorld)
