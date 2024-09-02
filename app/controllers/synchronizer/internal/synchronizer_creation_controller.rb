require_relative '../../wrappers/policy_wrapper'
require_relative '../../../domain/authentication/util/host_authentication'
require 'digest'

class SynchronizerCreationController < V2RestController
  include SynchronizerYamls
  include GroupMembershipValidator
  include PolicyWrapper
  include AccountValidator
  include HostAuthentication

  def generate_install_token
    logger.debug{LogMessages::Endpoints::EndpointRequested.new("synchronizer/installer-creds endpoint started")}
    validate_conjur_admin_group(account)
    synchronizer_uuid = tenant_id
    begin
      # create the installer token
      synchronizer_installer_resource_id = "#{account}:host:synchronizer/synchronizer-installer-#{synchronizer_uuid}/synchronizer-installer-host-#{synchronizer_uuid}"
      synchronizerHostResource = Resource.find(resource_id: synchronizer_installer_resource_id)
      raise Exceptions::RecordNotFound.new(synchronizer_installer_resource_id, message: "Synchronizer host not found") if synchronizerHostResource.nil?
      installer_token = get_access_token(account, synchronizer_installer_resource_id, request)
      response.set_header("Content-Encoding", "base64")
      response.set_header("Content-Type", "text/plain")

      # synchronizer host id by synchronizer-component-template required
      synchronizer_host_resource_id = "host/synchronizer/synchronizer-#{synchronizer_uuid}/synchronizer-host-#{synchronizer_uuid}"

      render(plain: Base64.strict_encode64(synchronizer_host_resource_id + ":" + installer_token))
      logger.debug{LogMessages::Endpoints::EndpointFinishedSuccessfully.new("synchronizer/installer-creds endpoint succeeded")}
    rescue => e
      @error_message = e.message
      logger.error(LogMessages::Conjur::GeneralError.new(e.message))
      raise e
    ensure
      token_generation_audit(synchronizer_installer_resource_id)
    end
  end
  def create_synchronizer
    logger.debug{LogMessages::Endpoints::EndpointRequested.new("create synchronizer endpoint")}
    validate_conjur_admin_group(account)
    synchronizer_uuid = tenant_id

    begin
      synchronizer_host_resource_id = "#{account}:host:synchronizer/synchronizer-#{synchronizer_uuid}/synchronizer-host-#{synchronizer_uuid}"
      synchronizerHostResource = Resource.find(resource_id: synchronizer_host_resource_id)
      raise Exceptions::RecordExists.new("synchronizer", synchronizer_host_resource_id) if not synchronizerHostResource.nil?
      add_synchronizer_host_policy(synchronizer_uuid)

      head :created
      logger.debug{LogMessages::Endpoints::EndpointFinishedSuccessfully.new("synchronizer created - #{synchronizer_uuid}")}

    rescue Exceptions::RecordExists => e
      logger.warn(LogMessages::Conjur::AlreadyExists.new(synchronizer_uuid, e.message))
      raise e
    rescue => e
      @error_message = e.message
      logger.warn(LogMessages::Conjur::GeneralError.new(e.message))
      raise e
    ensure
      created_audit(synchronizer_host_resource_id)
    end
  end

  private

  def token_generation_audit(synchronizer_id = "not-found")
    audit_params = { synchronizer_id: synchronizer_id, user: current_user.role_id, client_ip: request.ip}
    audit_params[:error_message] = @error_message if @error_message
    Audit.logger.log(Audit::Event::TokenGeneration.new(
      **audit_params
    ))
  end

  def created_audit(synchronizer_id = "not-found")
    audit_params = { synchronizer_id: synchronizer_id, user: current_user.role_id, client_ip: request.ip}
    audit_params[:error_message] = @error_message if @error_message
    Audit.logger.log(Audit::Event::SynchronizerCreation.new(
      **audit_params
    ))
  end

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
