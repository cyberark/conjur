
class HostsController < RestController
  
  def edge_hosts
    logger.info(LogMessages::Conjur::EndpointRequested.new("edge_hosts"))
    allowed_params = %i[account]
    options = params.permit(*allowed_params).to_h.symbolize_keys
    begin
      verify_host(options)
    rescue ApplicationController::Forbidden
      raise
    end
    
    hosts = Role.where(:role_id.like(options[:account]+":host:edge/%"))
    results = []
    hosts.each do |host|
      host_to_return = {}
      id = host[:role_id]
      host_name = host.split['/'].last
      host_to_return[:id] = id
      host_to_return[:name] = host_name
      results  << host_to_return
    end
    logger.info(LogMessages::Conjur::EndpointFinishedSuccessfully.new("edge_hosts"))
    render(json:{"hosts": results})
  end
  
  def verify_host(options)
    msg = ""
    raise_excep = false

    if %w[conjur cucumber rspec].exclude?(options[:account])
      raise_excep = true
      msg = "Account is: #{options[:account]}. Should be one of the following: [conjur cucumber rspec]"
    
    else
      role = Role[options[:account] + ':group:Conjur_Cloud_Admins']
      unless role&.ancestor_of?(current_user)
        raise_excep = true
        msg = "Curren user is: #{current_user}. should be member of #{role}"
      end
    end

    if raise_excep
      logger.error(
        Errors::Authorization::EndpointNotVisibleToRole.new(
          msg
        )
      )
      raise Forbidden
    end
  end
end
