require_dependency "conjur_audit/application_controller"

module ConjurAudit
  class MessagesController < ApplicationController
    def index
      render json: messages, status: messages.any? ? :ok : :not_found
    end

    private

    DIRECT_FIELDS = %i(facility severity hostname appname procid msgid).freeze
    
    def query
      @query ||= request.query_parameters
    end

    def direct_filter
      query.slice(*DIRECT_FIELDS)
    end
    
    # filter on RFC 5424 structured data
    # eg. subject@43868/role=foo looks for [subject@43868 role="foo"]
    def data_filter
      query.except(*DIRECT_FIELDS).each_with_object({}) do |kv, filter|
        key, value = kv
        id, param = key.to_s.split '/'
        (filter[id] ||= {})[param] = value
      end
    end
    
    def messages_with_data_filter
      filter = data_filter
      filter.empty? ? Message : Message.matching_sdata(filter)
    end
    
    def messages
      @messages ||= messages_with_data_filter.where_all(direct_filter)
    end
  end
end
