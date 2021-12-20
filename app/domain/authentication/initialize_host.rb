#frozen_string_literal: true

require 'command_class'

module Authentication

  class AuthHostDetails
    include ActiveModel::Validations
    attr_reader :id, :annotations

    def initialize(raw_post)
      @json_data = JSON.parse(raw_post)

      # TODO: Could use metaprogramming here to simplify?
      @id = @json_data['id'] if @json_data.include?('id')
      @annotations = @json_data['annotations'] if @json_data.include?('annotations')
    end

    def json_parameters
      [ 'id', 'annotations' ]
    end

    validates(
      :id,
      presence: true
    )

    validates_each :annotations do |record, attr, value|
      # NOTE: We allow nil as a possible value for the annotations attribute
      unless value.nil?
        # If annotations is present it must be a populated hash map
        record.errors.add(attr, message: "must be an object") unless value.is_a?(Hash)
        record.errors.add(attr, message: "must not be empty") if value.empty?

        # We already know each key is a string because it is the definition of JSON
        value.each_pair { |key, value| record.errors.add(attr, "object values must be strings") unless value.is_a?(String) }
      end
    end
  end

  class InitializeAuthHost
    extend CommandClass::Include

    command_class(
      dependencies: {
        logger: Rails.logger,
        auth_initializer: Authentication::Default::InitializeDefaultAuth.new,
      },
      inputs: %i[conjur_account authenticator service_id resource current_user client_ip host_data]
    ) do
      def call
        policy_details = initialize_host_policy

        raise ArgumentError, @host_data.errors.full_messages unless @host_data.valid?

        host_policy
      rescue => e
        raise e
      end

      private

      def host_policy
        @host_policy ||= ApplicationController.renderer.render(
          template: "policies/authn-k8s-host",
          locals: {
            service_id: @service_id,
            authenticator: @authenticator,
            hosts: [ @host_data ]
          }
        )
      end

      def initialize_host_policy
        Policy::LoadPolicy.new.(
          delete_permitted: false,
          action: :update,
          resource: @resource,
          policy_text: host_policy,
          current_user: @current_user,
          client_ip: @client_ip
        )
      end
    end
  end

end
