# AuthenticationService represents the authenticator itself, which 
# has a Conjur id that:
#
# * Identifies a policy.
# * Identifies a webservice.
# * Is a naming prefix to CA cert and key variables.
# * Is a naming prefix to the application hosts.
module Authentication
  module AuthnK8s
    class AuthenticationService
      attr_reader :id

      # Constructs AuthenticationService from the +id+, which is typically something like
      # conjur/authn-k8s/<cluster-name>.
      def initialize id
        @id = id
      end

      # Generates a CA certificate and key and store them in Conjur variables.  
      def initialize_ca
        subject = "/CN=#{id.gsub('/', '.')}/OU=Conjur Kubernetes CA/O=#{conjur_account}"

        cert, key = CA.generate subject

        if master_host
          appliance_url = "https://#{master_host}/api"
          configuration = Conjur.configuration.clone appliance_url: appliance_url
          host = nil
          Conjur.with_configuration configuration do
            populate_ca_variables cert, key
          end
          wait_for_variable ca_cert_variable, cert
          wait_for_variable ca_key_variable, key
        else
          populate_ca_variables cert, key
        end
      end

      def conjur_account
        Conjur.configuration.account
      end

      def ca_cert_variable
        Resource["#{conjur_account}:variable:#{id}/ca/cert"]
      end

      def ca_key_variable
        Resource["#{conjur_account}:variable:#{id}/ca/key"]
      end

      # Initialize CA from Conjur variables
      def load_ca
        ca_cert = OpenSSL::X509::Certificate.new(ca_cert_variable.value)
        ca_key = OpenSSL::PKey::RSA.new(ca_key_variable.value)
        CA.new(ca_cert, ca_key)
      end

      protected
      
      # Gets an access token for the policy role.
      def policy_token
        @policy_token ||= Conjur::API.authenticate_local "policy/#{id}"
      end

      # Stores the CA cert and key in variables.
      def populate_ca_variables cert, key
        ca_cert_variable.add_value cert.to_pem
        ca_key_variable.add_value key.to_pem
      end

      # In the case that this node is a follower, it's necessary to wait for the
      # variables to be replicated from the master.
      def wait_for_variable var, value
        while true
          begin
            break if var.value == value.to_pem
          rescue
            logger.debug "Waiting for #{var} to replicate to me..."
            sleep 2
          end
        end
      end

      # On a follower, the CONJUR_MASTER_HOST environment variable contains the
      # URL to the master cluster.
      def master_host
        ENV['CONJUR_MASTER_HOST']
      end
    end
  end
end
