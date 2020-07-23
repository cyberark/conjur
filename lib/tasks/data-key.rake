# frozen_string_literal: true

namespace :"data-key" do
  desc "Create a data encryption key, which should be placed in the environment as CONJUR_DATA_KEY"
  task :generate do
    require 'slosilo'
    require 'base64'
    key = Base64.strict_encode64(Slosilo::Symmetric.new.random_key)
    print key
  end

  desc "Validates the value of ENV['CONJUR_DATA_KEY']"
  # This task validates the master data key that is stored in `ENV['CONJUR_DATA_KEY']`
  # The task runs in two modes:
  # First mode:
  # ==========
  #   Once the database is created, a role + resource + secret will be created using the master key.
  #
  # Second mode:
  # ===========
  #   Each time the server restarts this task will attempt to retrieve the
  #   secret. If the provided key does not match the original Conjur data key, the secret decryption
  #   will fail and the task will exit with an error.
  #
  # Side Note
  # =========
  #  What's the 'environment' task in Rake?
  #  the :validate => :environment means "do environment before validate".
  #  You can get access to your models, and in fact, your whole environment
  #  by making tasks dependent on the environment task.
  task :validate => [:environment] do
    data_key = ENV['CONJUR_DATA_KEY']

    if data_key.nil? || data_key.empty?
      raise Errors::System::EmptyConjurDataKey
    end

    # try get the Conjur data key validator resource
    resource_id = "!:!:data-key-validator-resource"
    if Resource[resource_id]
      # Server restart - verify we can decrypt the secret
      begin
        # Attempt to retrieve the secret encrypt with the original data key.
        # A failure to decrypt the value will indicate the key is invalid.
        Resource[resource_id].secret.value
      rescue => OpenSSL::Cipher::CipherError
        raise Errors::System::InvalidConjurDataKey
      rescue => e
        warn "Error retrieving data-key validator secret in Resource[#{resource_id}], Error: #{e.inspect}"
        exit 1
      end
    else
      # Server first run
      # create the master key validator resource
      # and store a secret using the master key
      role_id = "!:!:data-key-validator"

      begin
        Role.create(role_id: role_id)
        Resource.create(resource_id: resource_id, owner_id: role_id)
        Secret.create(resource_id: resource_id, value: "data-key-validator-secret")
      rescue => e
        $stderr.puts "Error creating a resource for data key validation, Error: #{e.inspect}"
      end
    end
  end
end
