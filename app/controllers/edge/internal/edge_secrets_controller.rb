require_relative '../../../domain/edge_logic/replication_handler'

class EdgeSecretsController < RestController
  include AccountValidator
  include BodyParser
  include Cryptography
  include EdgeValidator
  include ExtractEdgeResources
  include GroupMembershipValidator
  include ReplicationHandler

  #def run_with_transaction(&block)
  #  if (ENV['IS_SECRETS_TRANSACTION_ON'] == 'YES')
  #    Sequel::Model.db.transaction(&block)
  #  end
  #end

  # Return all secrets within offset-limit frame. Default is 0-1000
  def all_secrets
    logger.info(LogMessages::Endpoints::EndpointRequested.new("all_secrets"))

    allowed_params = %i[account limit offset]
    options = params.permit(*allowed_params)
                    .slice(*allowed_params).to_h.symbolize_keys
    sumItems = 0
    begin

      verify_edge_host(options)
      Rails.logger.info("++++++++++++++ all_secrets +++++++++++++")
      #scope = Resource.where(:resource_id.like(options[:account] + ":variable:data/%").and())

      if params[:count] == 'true'

        count_query = "SELECT count(*) from allowed_secrets_per_role1('" + current_user.id + "','conjur:variable:data/%', '10000000', '0')"

        #count_query = "SELECT count(*) FROM resources WHERE (resources.resource_id LIKE '" +
        #  options[:account] + ":variable:data/%') AND ( resources.owner_id = '" + current_user.id + "' OR " +
        #  " resources.resource_id in (SELECT permissions.resource_id from permissions WHERE permissions.role_id = '" +
        #    current_user.id + "' AND permissions.privilege = 'execute' AND permissions.resource_id = resources.resource_id) )"
        Rails.logger.info("++++++++++++++ count_query = #{count_query}")
        Sequel::Model.db.fetch(count_query) do |row|
          Rails.logger.info("++++++++++++++ row = #{row}")
          sumItems = row[:count]
          Rails.logger.info("++++++++++++++ do sumItems = #{sumItems}")
          break
        end
        Rails.logger.info("++++++++++++++ sumItems = #{sumItems}")
      else
        offset = options[:offset] || "0"
        limit = options[:limit] || "1000"
        validate_scope(limit, offset)
      end
    rescue ApplicationController::Forbidden
      raise
    rescue ArgumentError => e
      raise ApplicationController::UnprocessableEntity, e.message
    end

    if params[:count] == 'true'
      results = { count: sumItems }
      logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfully.new("all_secrets:count"))
      render(json: results)
    else
      accepts_base64 = String(request.headers['Accept-Encoding']).casecmp?('base64')
      if accepts_base64
        response.set_header("Content-Encoding", "base64")
      end

      results, failed = replicate_secrets(limit, offset, options, accepts_base64)

      logger.info(LogMessages::Endpoints::EndpointFinishedSuccessfullyWithLimitAndOffset.new(
        "all_secrets",
        limit,
        offset
      ))
      if (failed.size > 0)
        logger.info(LogMessages::Util::FailedSerializationOfResources.new(
          "all_secrets",
          limit,
          offset,
          failed.size,
          failed.first
        ))
      end
      #results = []
      #failed = false
      render(json: { "secrets": results, "failed": failed })
    end
  end

end
