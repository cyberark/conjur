#frozen_string_literal: true

require 'command_class'

module Authentication

  class AuthHostDetails
    include ActiveModel::Validations
    attr_reader :id, :annotations

    def initialize(raw_post, constraints: nil)
      @json_data = JSON.parse(raw_post)
      @constraints = constraints

      @id = @json_data['id'] if @json_data.include?('id')
      @annotations = @json_data['annotations'] if @json_data.include?('annotations')
    end

    def annotation_pattern
      /authn-[a-z8]+\//
    end

    # Get annotations defining authenticator variables (formatted as authn-<authenticator>/<annotation name>)
    # We have to do this in order to allow users to define custom annotations
    def auth_annotations
      @annotations.keys.keep_if { |annotation| annotation.start_with?(annotation_pattern) } unless @annotations.nil?
    end

    def validate_annotations
      unless @constraints.nil? or auth_annotations.nil?
        # remove the authn-<authenticator>/ prefix from each authenticator
        pruned_annotations = auth_annotations.map {|annot| annot.sub(annotation_pattern, '')}
        @constraints.validate(resource_restrictions: pruned_annotations)
      end
    end

    validates(
      :id,
      presence: true
    )

    validate :validate_annotations
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
