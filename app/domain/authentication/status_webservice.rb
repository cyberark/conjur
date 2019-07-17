# frozen_string_literal: true

require 'types'
require 'dry-struct'

module Authentication
  class StatusWebservice < ::Dry::Struct

    attr_reader :parent_webservice
    attribute :resource_class, (::Types::Any.default { ::Resource })

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
      @resource ||= resource_class[resource_id]
    end

    def authenticator_name
      @parent_webservice.authenticator_name
    end
  end
end
