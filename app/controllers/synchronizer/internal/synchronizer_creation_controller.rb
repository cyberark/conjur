require_relative '../../wrappers/policy_wrapper'
require 'digest'

class SynchronizerCreationController < V2RestController
  include SynchronizerYamls
  include GroupMembershipValidator
  include PolicyWrapper
  include AccountValidator
  def create_synchronizer
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("create synchronizer endpoint"))
    validate_conjur_admin_group(account)
    synchronizer_uuid = tenant_id

    begin
      synchronizer_host_resource_id = "#{account}:host:synchronizer/synchronizer-#{synchronizer_uuid}/synchronizer-host-#{synchronizer_uuid}"
      synchronizerHostResource = Resource.find(resource_id: synchronizer_host_resource_id)

      if not synchronizerHostResource.nil?
        raise Exceptions::RecordExists.new("synchronizer", synchronizer_host_resource_id)
      end
      add_synchronizer_host_policy(synchronizer_uuid)

      head :created
      logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("synchronizer created - #{synchronizer_uuid}"))

    rescue Exceptions::RecordExists => e
      logger.warn(LogMessages::Conjur::AlreadyExists.new(synchronizer_uuid, e.message))
      raise e
    rescue => e
      logger.warn(LogMessages::Conjur::GeneralError.new(e.message))
      raise e
    end
  end

  private

  def hash_string(input_string)
    hashed_string = Digest::SHA256.hexdigest(input_string)
    return hashed_string
  end

  def tenant_id
    tenant_id = Rails.application.config.conjur_config.tenant_id
    return hash_string(tenant_id)
  end

  def add_synchronizer_host_policy(host_id)
    input = input_post_yaml(host_id)
    resource = Resource["#{account}:policy:synchronizer"]
    submit_policy(Loader::CreatePolicy, PolicyTemplates::CreateSynchronizer.new(), input, resource)
  end

end
