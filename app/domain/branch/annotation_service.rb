# frozen_string_literal: true

require 'singleton'
require_relative 'domain'

module Domain
  class AnnotationService
    include Singleton
    include Domain

    def initialize(
      annotation_repo: ::Annotation
    )
      @annotation_repo = annotation_repo
    end

    def read_ann(resource_id, name)
      @annotation_repo.where(resource_id: resource_id, name: name.to_s).first
    end

    def create_ann(resource_id, name, value, policy_id)
      @annotation_repo.create(
        resource_id: resource_id,
        name: name,
        value: value,
        policy_id: policy_id
      ).save
    end

    def upsert_ann(resource_id, policy_id, a_key, a_value)
      ann = read_ann(resource_id, a_key)

      if ann.nil?
        create_ann(resource_id, a_key, a_value, policy_id)
      else
        ann.update(value: a_value)
      end
    end
  end
end
