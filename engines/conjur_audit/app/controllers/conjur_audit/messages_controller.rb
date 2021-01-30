# frozen_string_literal: true

require_dependency "conjur_audit/application_controller"

module ConjurAudit
  class MessagesController < ApplicationController
    def index
      render json: messages_json, status: messages.any? ? :ok : :not_found
    end

    private

    DIRECT_FIELDS = %i[facility severity hostname appname procid msgid].freeze

    PAGING_FIELDS = %i[limit offset].freeze
    
    def query
      @query ||= request.query_parameters
    end

    def direct_filter
      query.slice(*DIRECT_FIELDS)
    end
    
    def sdata_query
      query.except(*DIRECT_FIELDS, *PAGING_FIELDS, :resource, :role, :entity)
    end

    # filter on RFC 5424 structured data
    # eg. subject@43868/role=foo looks for [subject@43868 role="foo"]
    def data_filter
      sdata_query.each_with_object({}) do |kv, filter|
        key, value = kv
        id, param = key.to_s.split '/'
        (filter[id] ||= {})[param] = value
      end
    end
    
    def messages_with_entity_filter
      msgs = Message
      if (id = params[:entity])
        msgs = msgs.matching_entity id
      end
      if (res = params[:resource])
        msgs = msgs.matching_resource res
      end
      if (rol = params[:role])
        msgs = msgs.matching_role rol
      end
      msgs
    end

    def messages_with_data_filter
      filter = data_filter
      msgs = messages_with_entity_filter
      filter.empty? ? msgs : msgs.matching_sdata(filter)
    end
    
    def messages
      dataset = messages_with_data_filter.where(direct_filter).order(Sequel.desc(:timestamp))

      if (offset = params[:offset])
        dataset = dataset.offset(offset)
      end

      if (limit = params[:limit])
        dataset = dataset.limit(limit)
      end

      @messages ||= dataset
    end

    # Convert messages to JSON.
    # Note: For performance, we use JSON.dump directly.
    # Giving messages to render(json:) renders it using ActiveSupport
    # which does a lot of things we don't need and is an order of
    # magnitude slower.
    def messages_json
      JSON.dump messages.map(&:to_hash)
    end
  end
end
