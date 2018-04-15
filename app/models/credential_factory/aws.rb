module CredentialFactory
  Aws = Struct.new(:resource, :dependent_secrets) do
    include Base

    class << self
      # access_key_id, secret_access_key, and region are required configuration variables.
      def dependent_variable_ids annotations
        secret_access_key = require_annotation(annotations, 'credential-factory/secret_access_key')
        build_variable_ids secret_access_key, %w(access_key_id secret_access_key region)
      end
    end

    def access_key_id
      dependent_secrets[:access_key_id]
    end

    def secret_access_key
      dependent_secrets[:secret_access_key]
    end

    def region
      dependent_secrets[:region]
    end

    def policy
      require_annotation('credential-factory/policy')
    end

    def duration_seconds
      ( annotations['credential-factory/duration-seconds'] ||
        1.hour ).to_i
    end

    def federated_user_name
      ( annotations['credential-factory/user-name'] || resource.identifier ).underscore.gsub('/', '-')
    end

    # Example response:
    #
    # {
    #   "access_key_id": "ASIAI6...F7KPBKA",
    #   "secret_access_key": "EhyQYceI...arRtkZfYugB9dDM6",
    #   "session_token": "FQoDYXdzEH4aD...7bz7Nw+NL0mKNr8ztYF",
    #   "expiration": "2018-04-15 22:04:26 UTC",
    #   "federated_user_id": "<acct-id>:myapp",
    #   "federated_user_arn": "arn:aws:sts::<acct-id>:federated-user/myapp"
    # }
    def values
      require 'aws-sdk-sts'
      resp = ::Aws::STS::Client.new(access_key_id: access_key_id, 
        secret_access_key: secret_access_key,
        region: region).get_federation_token duration_seconds: duration_seconds,
        name: federated_user_name, 
        policy: policy

      resp.to_h[:credentials].merge({
        federated_user_id: resp.federated_user.federated_user_id,
        federated_user_arn: resp.federated_user.arn
      })
    end
  end
end
