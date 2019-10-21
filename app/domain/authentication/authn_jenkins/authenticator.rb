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

      def build_running?(response)
        body = response.body
        status_code = response.code

        Rails.logger.debug("Jenkins Build Response: #{body}")
        if status_code != 200
          raise Err::BuildInfoError.new("#{status_code} - #{body}")
        end

        JSON.parse(body)['building']
      end

      def parse_metadata(username, message_body)
        json_body = JSON.parse message_body

        build_number = json_body["buildNumber"]
        signature = Base64.decode64(json_body["signature"])
        job_property_host_prefix = json_body["jobProperty_hostPrefix"]
        if json_body.key?("jobProperty_hostPrefix")
          job_name = username.sub("host/#{job_property_host_prefix}/", "")
        else
          job_name = username.sub("host/", "")
        end
        job_path = job_name.split("/").join("/job/")

        return job_name, job_path, build_number, signature
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
            variables.variable("jenkinsPassword").secret.value
          )
        end
      end
      
      def valid?(input)
        # Parse the body
        # e.g {"buildNumber": 5, "signature": "<base64 signature>", "jobProperty_hostPrefix": "myapp"}
        load = JenkinsLoad.new(input.password, input.username)
      
        Rails.logger.debug("Job Name: #{load.job_name} | Build Number: #{load.build_number} | Signatature: #{load.signature}")
        jenkins_client(input.account, input.authenticator_name, input.service_id)
      
        # Validate job is running and signature was signed with the jenkins identities private key
        unless build_running?(@jenkins_client.build(load.job_path, load.build_number))
          Rails.logger.error("AUTHENTICATION FAILED: Job '#{load.job_name} ##{load.build_number}' is currently not running.")
          raise Err::RunningJobNotFound "#{load.job_name} ##{load.build_number}"
        end
        public_key = @jenkins_client.public_key
        message = "#{load.job_name}-#{load.build_number}"

        unless public_key.verify(OpenSSL::Digest::SHA256.new, load.signature, message)
          Rails.logger.error("AUTHENTICATION FAILED: Data tampered or private-public key mismatch.")
          raise Err::InvalidSignature
        end
        true
      end
    end
  end
end
