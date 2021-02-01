# frozen_string_literal: true

require 'command_class'

module Authentication
  module AuthnK8s

    ExtractContainerName ||= CommandClass.new(
      dependencies: {
        logger:                 Rails.logger
      },
      inputs: %i[service_id host_annotations]
    ) do

      DEFAULT_AUTHENTICATION_CONTAINER_NAME = "authenticator"

      def call
        container_name
      end

      private

      def container_name
        annotation_name = Restrictions::AUTHENTICATION_CONTAINER_NAME
        annotation_value("authn-k8s/#{@service_id}/#{annotation_name}") ||
          annotation_value("authn-k8s/#{annotation_name}") ||
          annotation_value("kubernetes/#{annotation_name}") ||
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
            Restrictions::AUTHENTICATION_CONTAINER_NAME,
            DEFAULT_AUTHENTICATION_CONTAINER_NAME
          )
        )

        DEFAULT_AUTHENTICATION_CONTAINER_NAME
      end
    end
  end
end
