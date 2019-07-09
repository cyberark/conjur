# frozen_string_literal: true

require 'util/fetch_resource'

module Authentication
  class StatusWebservice

    attr_reader :parent_webservice

    def self.from_webservice(webservice)
      self.new(webservice)
    end

    def initialize(parent_webservice)
      @parent_webservice = parent_webservice
    end

    def name
      @name ||= "#{@parent_webservice.name}/status"
    end

    def resource_id
      @resource_id ||= "#{@parent_webservice.resource_id}/status"
    end

    def resource
      @resource ||= Util::FetchResource.new.(resource_id: resource_id)
    end

    def authenticator_name
      @parent_webservice.authenticator_name
    end

    def annotation(name)
      resource&.annotation(name)
    end
  end
end
