require 'command_class'

module Authentication
  module AuthnK8s

    InjectClientCert = CommandClass.new(
      dependencies: {
        resource_repo: Resource,
        conjur_ca_repo: Repos::ConjurCA,
        k8s_object_lookup: K8sObjectLookup,
        kubectl_exec: KubectlExec,
        validate_pod_request: ValidatePodRequest.new
      },
      inputs: [:conjur_account, :service_id, :csr]
    ) do

      def call
        validate
        install_signed_cert
      end

      private

      def validate
        @validate_pod_request.(pod_request: pod_request)
        validate_csr
      end

      def install_signed_cert
        resp = @kubectl_exec.new.copy(
          pod_namespace: spiffe_id.namespace,
          pod_name: spiffe_id.name,
          path: "/etc/conjur/ssl/client.pem",
          content: cert_to_install.to_pem,
          mode: "0644"
        )
        validate_cert_installation(resp)
      end

      def pod_request
        PodRequest.new(
          service_id: @service_id,
          k8s_host: k8s_host,
          spiffe_id: spiffe_id
        )
      end

      def k8s_host
        @k8s_host ||= Authentication::AuthnK8s::K8sHost.from_csr(
          account: @conjur_account,
          service_name: @service_id,
          csr: @csr
        )
      end

      def host_id
        k8s_host.conjur_host_id
      end

      def spiffe_id
        @spiffe_id ||= SpiffeId.new(smart_csr.spiffe_id)
      end

      def pod
        @pod ||= @k8s_object_lookup.pod_by_name(
          spiffe_id.name, spiffe_id.namespace
        )
      end

      def host
        @host ||= @resource_repo[host_id]
      end

      def container_name
        name = 'kubernetes/authentication-container-name'
        annotation = host.annotations.find { |a| a.values[:name] == name }
        annotation[:value] || 'authenticator'
      end

      def validate_csr
        raise CSRIsMissingSpiffeId unless smart_csr.spiffe_id
        raise CSRNamespaceMismatch unless common_name.namespace == spiffe_id.namespace
      end

      def smart_csr
        @smart_csr ||= Util::OpenSsl::X509::SmartCsr.new(@csr)
      end

      def common_name
        @common_name ||= CommonName.new(smart_csr.common_name)
      end

      def validate_cert_installation(resp)
        return if resp[:error].empty?
        raise CertInstallationError, cert_error(resp[:error])
      end

      # In case there's a blank error message...
      def cert_error(msg)
        blank_msg = msg =~ /^\s*$/
        blank_msg ? 'The server returned a blank error message' : msg
      end

      def ca_for_webservice
        @conjur_ca_repo.ca(webservice.resource_id)
      end

      def webservice
        ::Authentication::Webservice.new(
          account: @conjur_account,
          authenticator_name: 'authn-k8s',
          service_id: @service_id
        )
      end

      def cert_to_install
        ca_for_webservice.signed_cert(
          @csr,
          subject_altnames: [ spiffe_id.to_altname ]
        )
      end
    end

  end
end
