# frozen_string_literal: true

# This is here to fix a double-loading bug that occurs only in openshift and
# K8s tests.  We don't fully understand what causes the bug but this is the
# hack we settled on to fix it.
#
if defined? Rotation::Rotators::Aws::SecretKey
  return
end

require 'aws-sdk-iam'

module Rotation
  module Rotators
    module Aws

      class SecretKey

        def initialize(iam_client: ::Aws::IAM::Client)
          @iam_client = iam_client
        end

        def rotate(facade)

          creds  = AwsCredentials.new(facade)
          client = @iam_client.new(creds.credentials)

          # Delete old keys on AWS
          key_metadata = client.list_access_keys.access_key_metadata
          key_metadata
            .select { |x| x['access_key_id'] != creds.access_key_id }
            .each { |x| client.delete_access_key(access_key_id: x['access_key_id']) }

          # New key on AWS
          new_key = client.create_access_key.access_key

          # Old key on AWS
          old_key = creds.conjur_ids[:access_key_id]

          # Update in conjur
          facade.update_variables(Hash[
            creds.conjur_ids[:access_key_id]    , new_key.access_key_id,
            creds.conjur_ids[:secret_access_key], new_key.secret_access_key
          ])

          # Delete key just used for rotation
          # This prevents leaving two active access keys
          client.delete_access_key(access_key_id: old_key)
        end

        private 

        AwsCredentials = ::Struct.new(:facade) do
          def access_key_id
            credentials[:access_key_id]
          end

          def conjur_ids
            @conjur_ids ||= {
              region: rotated_variable.sibling_id('region'),
              access_key_id: rotated_variable.sibling_id('access_key_id'),
              secret_access_key: rotated_variable.resource_id
            }
          end

          # conjur_facade returns a {resource_id: value} hash.  This returns a
          # {variable_name: value} hash, suitable for passing to the AWS
          # client.  Essentially, translated fully-qualified resource_ids to
          # local names
          #
          def credentials
            return @credentials if @credentials

            keys = %i[region access_key_id secret_access_key]
            vals = facade.current_values(keys.map(&conjur_ids))
            @credentials = keys.map { |k| [ k, vals[conjur_ids[k]] ] }.to_h
          end

          private

          def rotated_variable
            facade.rotated_variable
          end
        end
      end

    end
  end
end
