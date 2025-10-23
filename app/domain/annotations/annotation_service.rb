# frozen_string_literal: true

require 'singleton'

module Annotations
  class AnnotationService
    include Singleton
    include Domain
    include Logging

    def initialize(
      annotation_repo: ::Annotation,
      logger: Rails.logger
    )
      @annotation_repo = annotation_repo
      @logger = logger
    end

    def fetch_annotation(resource_id, name)
      log_debug("resource_id = #{resource_id}, name = #{name}")

      @annotation_repo.where(resource_id: resource_id, name: name.to_s).first
    end

    def create_annotation(resource_id, name, value, policy_id)
      log_debug("resource_id = #{resource_id}, name = #{name}, value = #{value}")

      @annotation_repo.create(
        resource_id: resource_id,
        name: name,
        value: value,
        policy_id: policy_id
      ).save
    end

    def upsert_annotation(resource_id, policy_id, a_key, a_value)
      log_debug("resource_id = #{resource_id}, policy_id = #{policy_id}, a_key = #{a_key}, a_value = #{a_value}")

      annotation = fetch_annotation(resource_id, a_key)
      log_debug("annotation = #{annotation}")

      if annotation.nil?
        create_annotation(resource_id, a_key, a_value, policy_id)
      else
        annotation.update(value: a_value)
      end
    end

    def delete_annotation(resource_id, annotation_name)
      log_debug("resource_id = #{resource_id}, annotation_name = #{annotation_name}")

      annotation = fetch_annotation(resource_id, annotation_name)
      log_debug("annotation = #{annotation}")

      return annotation.destroy unless annotation.nil?

      raise ApplicationController::RecordNotFound.new(resource_id.to_s, message: "Annotation '#{annotation_name}' not found in resource '#{resource_id}'")
    end
  end
end
