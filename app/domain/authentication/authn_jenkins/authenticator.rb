# frozen_string_literal: true
require 'json'

module Authentication
  module AuthnJenkins
    class Authenticator

      Err = Errors::Authentication::AuthnJenkins
      def initialize(env:)
        @env = env
      end

      def webservice(account, authenticator_name, service_id)
        @webservice ||= ::Authentication::Webservice.new(
          account:            account,
          authenticator_name: authenticator_name,
          service_id:         service_id
        )
      end

      def jenkins_client(account, authenticator_name, service_id)
        @jenkins_client ||= begin
          variables = webservice(
            account,
            authenticator_name,
            service_id
          )
          JenkinsClient.new(
            variables.variable("jenkinsURL").secret.value,
            variables.variable("jenkinsUsername").secret.value,
            variables.variable("jenkinsPassword").secret.value,
            variables.variable("jenkinsCertificate").secret.value,
            variables.annotation("allow-http")
          )
        end
      end

      def build_running?(response)
        body = response.body
        status_code = response.code

        Rails.logger.debug("Jenkins Build Response: #{body}")
        if status_code != 200
          raise Err::BuildInfoError.new("#{status_code} - #{body}")
        end

        JSON.parse(body)['building']
      end
      
      def valid?(input)
        # Parse the body
        # e.g {"buildNumber": 5, "signature": "<base64 signature>", "jobProperty_hostPrefix": "myapp"}
        load = JenkinsLoad.new(input.password, input.username)
      
        Rails.logger.debug("Job Name: #{load.job_name} | Build Number: #{load.build_number} | Signatature: #{load.signature}")
        jenkins_client(input.account, input.authenticator_name, input.service_id)

        # validate signature with public key
        public_key = @jenkins_client.public_key
        message = "#{load.job_name}-#{load.build_number}"
  
        unless public_key.verify(OpenSSL::Digest::SHA256.new, load.signature, message)
          Rails.logger.error("AUTHENTICATION FAILED: Data tampered or private-public key mismatch.")
          raise Err::InvalidSignature
        end
      
        # Validate job is currently running
        unless build_running?(@jenkins_client.build(load.job_path, load.build_number))
          Rails.logger.error("AUTHENTICATION FAILED: Job '#{load.job_name} ##{load.build_number}' is currently not running.")
          raise Err::RunningJobNotFound "#{load.job_name} ##{load.build_number}"
        end
        true
      end
    end
  end
end
