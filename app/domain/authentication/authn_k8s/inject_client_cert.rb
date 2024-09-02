# frozen_string_literal: true

require 'command_class'

module Authentication
  module AuthnK8s

    InjectClientCert ||= CommandClass.new(
      dependencies: {
        logger: Rails.logger,
        resource_class: Resource,
        conjur_ca_repo: Repos::ConjurCA,
        copy_text_to_file_in_container: CopyTextToFileInContainer.new,
        validate_pod_request: ValidatePodRequest.new,
        extract_container_name: ExtractContainerName.new,
        audit_log: ::Audit.logger
      },
      inputs: %i[conjur_account service_id csr host_id_prefix client_ip]
    ) do
      # :reek:TooManyStatements
      def call
        update_csr_common_name
        validate
        install_signed_cert
        audit_success
      rescue => e
        audit_failure(e)
        raise e
      end

      private

      # In the old version of the authn-client we assumed that the host is under the "apps" policy branch.
      # Now we send the host-id in 2 parts:
      #   suffix - the host id
      #   prefix - the policy id
      # We update the CSR's common_name to have the full host-id. This way, the validation
      # that happens in the "authenticate" request will work, as the signed certificate
      # contains the full host-id.
      def update_csr_common_name
        @logger.debug{
          LogMessages::Authentication::AuthnK8s::SetCommonName.new(
            full_host_name
          )
        }
        smart_csr.common_name = full_host_name
      end

      def full_host_name
        "#{common_name_prefix}.#{smart_csr.common_name}"
      end

      def common_name_prefix
        @host_id_prefix.nil? || @host_id_prefix.empty? ? apps_host_id_prefix : @host_id_prefix
      end

      def apps_host_id_prefix
        "host.conjur.authn-k8s.#{@service_id}.apps"
      end

      def validate
        # We validate the CSR first since the pod_request uses its values
        validate_spiffe_id_exists

        @validate_pod_request.(pod_request: pod_request)
      end

      def install_signed_cert
        pod_namespace  = spiffe_id.namespace
        pod_name       = spiffe_id.name
        cert_file_path = "/etc/conjur/ssl/client.pem"
        @logger.debug{
          LogMessages::Authentication::AuthnK8s::CopySSLToPod.new(
            container_name,
            cert_file_path,
            pod_namespace,
            pod_name
          )
        }

        @copy_text_to_file_in_container.call(
          webservice: webservice,
          pod_namespace: pod_namespace,
          pod_name: pod_name,
          container: container_name,
          path: cert_file_path,
          content: cert_to_install.to_pem,
          mode: "644"
        )

        @logger.debug{LogMessages::Authentication::AuthnK8s::InitializeCopySSLToPodSuccess.new}
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
          csr: smart_csr
        )
      end

      def host_id
        k8s_host.conjur_host_id
      end

      def spiffe_id
        @spiffe_id ||= SpiffeId.new(smart_csr.spiffe_id)
      end

      def host
        return @host if @host

        @host = @resource_class[host_id]

        raise Errors::Authentication::Security::RoleNotFound, host_id unless @host

        @host
      end

      def validate_spiffe_id_exists
        raise Errors::Authentication::AuthnK8s::CSRIsMissingSpiffeId unless smart_csr.spiffe_id
      end

      def smart_csr
        @smart_csr ||= ::Util::OpenSsl::X509::SmartCsr.new(@csr)
      end

      def common_name
        @common_name ||= CommonName.new(smart_csr.common_name)
      end

      def ca_for_webservice
        @conjur_ca_repo.ca(webservice.resource_id)
      end

      def webservice
        ::Authentication::Webservice.new(
          account: @conjur_account,
          authenticator_name: AUTHENTICATOR_NAME,
          service_id: @service_id
        )
      end

      def cert_to_install
        ca_for_webservice.signed_cert(
          smart_csr,
          subject_altnames: [spiffe_id.to_altname]
        )
      end

      def container_name
        @extract_container_name.call(
          service_id: @service_id,
          host_annotations: host.annotations
        )
      end

      def audit_success
        @audit_log.log(
          Audit::Event::Authn::InjectClientCert.new(
            authenticator_name: AUTHENTICATOR_NAME,
            service: webservice,
            role_id: sanitized_role_id,
            client_ip: @client_ip,
            success: true,
            error_message: nil
          )
        )
      end

      def audit_failure(err)
        @audit_log.log(
          Audit::Event::Authn::InjectClientCert.new(
            authenticator_name: AUTHENTICATOR_NAME,
            service: webservice,
            role_id: sanitized_role_id,
            client_ip: @client_ip,
            success: false,
            error_message: err.message
          )
        )
      end

      # TODO: this logic is taken from app/models/audit/event/authn.rb.
      # We should use that logic here.
      # Masking role if it doesn't exist to avoid audit pollution
      def sanitized_role_id
        return "not-found" unless @resource_class[host_id]

        host.id
      end
    end
  end
end
