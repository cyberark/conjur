# frozen_string_literal: true

require 'json'
require_relative '../controllers/wrappers/policy_wrapper'
require_relative '../controllers/wrappers/policy_audit'
require_relative '../controllers/wrappers/templates_renderer'

class Issuer < Sequel::Model

  EPHEMERAL_ANNOTATION_PREFIX = "ephemeral/"
  EPHEMERAL_VARIABLE_PREFIX = "data/ephemerals/"

  attr_encrypted :data, aad: :issuer_id

  unrestrict_primary_key

  def as_json
    {
      id: self.issuer_id,
      max_ttl: self.max_ttl,
      type: self.issuer_type,
      data: JSON.parse(self.data),
      created_at: self.created_at,
      modified_at: self.modified_at
    }
  end

  def as_json_for_list
    {
      id: self.issuer_id,
      max_ttl: self.max_ttl,
      type: self.issuer_type,
      created_at: self.created_at,
      modified_at: self.modified_at
    }
  end

  def delete_issuer_variables
    # Find all the variables that belong to the account and start with the ephemrals prefix
    resource_ids = related_variables_query.select_map(:resource_id)
    Resource.where(resource_id: resource_ids).delete

    resource_ids
  end

  def issuer_variables_exist?
    !related_variables_query.empty?
  end

  private

  def related_variables_query
    Annotation.where(Sequel.lit("resource_id LIKE ? AND value = ? AND name = ?",
                                "#{self.account}:variable:#{EPHEMERAL_VARIABLE_PREFIX}%",
                                self.issuer_id, "#{EPHEMERAL_ANNOTATION_PREFIX}issuer"))
  end
end
