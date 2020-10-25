# frozen_string_literal: true

require 'command_class'

module Authentication
  module AuthnK8s

    ExtractContainerName ||= CommandClass.new(
      dependencies: {
        logger:                 Rails.logger
      },
      inputs: %i(service_id host_annotations)
    ) do

      AUTHENTICATION_CONTAINER_NAME_ANNOTATION = "authentication-container-name"
      DEFAULT_AUTHENTICATION_CONTAINER_NAME = "authenticator"

      def call
        container_name
      end

      private

      def container_name
        annotation_value("authn-k8s/#{@service_id}/#{AUTHENTICATION_CONTAINER_NAME_ANNOTATION}") ||
          annotation_value("authn-k8s/#{AUTHENTICATION_CONTAINER_NAME_ANNOTATION}") ||
          annotation_value("kubernetes/#{AUTHENTICATION_CONTAINER_NAME_ANNOTATION}") ||
          default_authentication_container_name
      end

      def annotation_value name
        annotation = @host_annotations.find { |a| a.values[:name] == name }

        # return the value of the annotation if it exists, nil otherwise
        if annotation
          @logger.debug(LogMessages::Authentication::ResourceRestrictions::RetrievedAnnotationValue.new(name))
          annotation[:value]
        end
      end

      def default_authentication_container_name
        @logger.debug(
          LogMessages::Authentication::ContainerNameAnnotationDefaultValue.new(
            AUTHENTICATION_CONTAINER_NAME_ANNOTATION,
            DEFAULT_AUTHENTICATION_CONTAINER_NAME
          )
        )

        DEFAULT_AUTHENTICATION_CONTAINER_NAME
      end
    end
  end
end
