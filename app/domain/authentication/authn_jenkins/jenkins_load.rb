module Authentication
  module AuthnJenkins
    class JenkinsLoad
      attr_reader :build_number, :signature, :job_name, :job_path
    
      def initialize(raw_body, username)
        body = JSON.parse(raw_body)
        @build_number = body['buildNumber']
        @signature = Base64.decode64(body['signature'])
        @job_name = if body['jobProperty_hostPrefix']
          username.sub("host/#{body['jobProperty_hostPrefix']}/", '')
        else
          username.sub('host/', '')
        end
        @job_path = @job_name.split('/').join('/job/')
      end
    end
  end
end
