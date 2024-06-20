require_relative '../../../domain/edge_logic/replication_handler'

class EdgeSecretsController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include ExtractEdgeResources
  include GroupMembershipValidator
  include ReplicationHandler

  def secrets
    if params[:id] 
      specific_secret
    else
      all_secrets
    end
  end

  # Return a specific secret
  def specific_secret
    logger.debug(LogMessages::Endpoints::EndpointRequested.new("specific_secret replication for edge '#{Edge.get_name_by_hostname(current_user.role_id)}'"))

    allowed_params = %i[account variable_id]
    options = params.permit(*allowed_params).slice(*allowed_params).to_h.symbolize_keys

    verify_edge_host(options)

    selective_enabled = ENV['SELECTIVE_REPLICATION_ENABLED'] || "false"
    accepts_base64 = String(request.headers['Accept-Encoding']).casecmp?('base64')
    if accepts_base64
      response.set_header("Content-Encoding", "base64")
    end

    begin
      results, failed = replicate_single_secret(params[:id], accepts_base64, selective_enabled) 

      if failed.empty?
        limit = 1
        offset = 0
        logger.debug(LogMessages::Util::FailedSerializationOfResources.new(
          "single secrets replication for edge '#{Edge.get_name_by_hostname(current_user.role_id)}'",
          limit,
          offset,
          failed.size,
          failed.first
        ))
      end
      render(json: { "secrets": results, "failed": failed })
      logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(
        "specific_secret replication for edge '#{Edge.get_name_by_hostname(current_user.role_id)}'"))
    rescue => e
      raise ApplicationController::InternalServerError, e.message
    end
  end

  # Return all secrets within offset-limit frame. Default is 0-1000
  def all_secrets
    logger.debug(LogMessages::Endpoints::EndpointRequested.new(
      "all_secrets replication for edge '#{Edge.get_name_by_hostname(current_user.role_id)}'"))

    allowed_params = %i[account limit offset]
    options = params.permit(*allowed_params)
                    .slice(*allowed_params).to_h.symbolize_keys
    sum_items = 0
    begin
      verify_edge_host(options)
      # selective replication currently disabled, this code will be removed after edge will get permissions for all variables
      selective_enabled = ENV['SELECTIVE_REPLICATION_ENABLED'] || "false"

      if params[:count] == 'true'
        if selective_enabled == "true"
          sum_items = do_count_selective(options)
        else
          sum_items = do_count(options)
        end

      else
        limit, offset = self.get_offset_limit(options)
        validate_scope(limit, offset)
      end
    rescue ApplicationController::Forbidden
      raise
    rescue ArgumentError => e
      raise ApplicationController::UnprocessableEntity, e.message
    end

    begin
      if params[:count] == 'true'
        generate_count_response(sum_items)
      else
        generate_secrets_result(limit, offset, options,selective_enabled)
      end
    rescue => e
      raise ApplicationController::InternalServerError, e.message
    end
  end

  private
  def get_offset_limit(options)
    offset = options[:offset] || "0"
    limit = options[:limit] || "1000"
    [limit, offset]
  end

  def generate_secrets_result(limit, offset, options,selective_enabled)
    accepts_base64 = String(request.headers['Accept-Encoding']).casecmp?('base64')
    if accepts_base64
      response.set_header("Content-Encoding", "base64")
    end
    results, failed = replicate_secrets(limit, offset, options, accepts_base64,selective_enabled)

    render(json: { "secrets": results, "failed": failed })
    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfullyWithLimitAndOffset.new(
      "all_secrets replication for edge '#{Edge.get_name_by_hostname(current_user.role_id)}'",
      limit,
      offset
    ))
    if failed.size > 0
      logger.debug(LogMessages::Util::FailedSerializationOfResources.new(
        "all_secrets replication for edge '#{Edge.get_name_by_hostname(current_user.role_id)}'",
        limit,
        offset,
        failed.size,
        failed.first
      ))
    end
  end

  def generate_count_response(sumItems)
    results = { count: sumItems }
    render(json: results)
    logger.debug(LogMessages::Endpoints::EndpointFinishedSuccessfully.new(
      "all_secrets:count replication for edge '#{Edge.get_name_by_hostname(current_user.role_id)}'"))
  end

  def do_count_selective(options)
    sum_items = 0
    count_query = "SELECT count(*) from allowed_secrets_per_role('" + current_user.id + "','" + options[:account] +":variable:data/%', '10000000', '0')"
    Sequel::Model.db.fetch(count_query) do |row|
      sum_items = row[:count]
      break
    end
    sum_items
  end

  def do_count(options)
    scope = Resource.where(:resource_id.like(options[:account] + ":variable:data/%"))
    scope.count('*'.lit)
  end
end
