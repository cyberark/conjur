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
      @annotations = @json_data.include?('annotations') ? @json_data['annotations'] : {}
    end

    private

    def annotation_pattern
      /authn-[a-z8]+\//
    end

    # Get annotations defining authenticator variables (formatted as authn-<authenticator>/<annotation name>)
    # We have to do this in order to allow users to define custom annotations
    def auth_annotations
      @annotations.keys.keep_if { |annotation| annotation.start_with?(annotation_pattern) }
    end

    def validate_annotations
      return if @constraints.nil?

      # remove the authn-<authenticator>/ prefix from each authenticator
      pruned_annotations = auth_annotations.map {|annot| annot.sub(annotation_pattern, '')}
      begin
        @constraints.validate(resource_restrictions: pruned_annotations)
      rescue => e
        errors.add(:annotations, e.message)
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
        policy_loader: Policy::LoadPolicy.new
      },
      inputs: %i[conjur_account authenticator service_id resource current_user client_ip host_data]
    ) do
      def call
        raise ArgumentError, @host_data.errors.full_messages unless @host_data.valid?

        initialize_host_policy[:policy].values[:policy_text]
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
        @policy_loader.(
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
