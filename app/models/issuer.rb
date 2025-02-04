# frozen_string_literal: true

require 'json'

# Issuer represents a backend service that "issues" dynamic, ephemeral
# credentials through an ephemeral secret engine.
class Issuer < Sequel::Model
  DYNAMIC_ANNOTATION_PREFIX = "dynamic/"
  DYNAMIC_VARIABLE_PREFIX = "data/dynamic/"

  attr_encrypted :data, aad: :issuer_id

  many_to_one :policy, class: :Resource, key: :policy_id

  unrestrict_primary_key

  def as_json
    {
      id: issuer_id,
      account: account,
      max_ttl: max_ttl,
      type: issuer_type,
      data: JSON.parse(data),
      created_at: created_at,
      modified_at: modified_at
    }
  end

  def delete_issuer_variables
    # Find all the variables that belong to the account and start with the
    # dynamic data prefix.
    resource_ids = related_variables_query.select_map(:resource_id)
    Resource.where(resource_id: resource_ids).destroy
    resource_ids
  end

  def issuer_variables_exist?
    !related_variables_query.empty?
  end

  private

  def related_variables_query
    Annotation.where(
      Sequel.lit(
        "resource_id LIKE ? AND value = ? AND name = ?",
        "#{account}:variable:#{DYNAMIC_VARIABLE_PREFIX}%",
        issuer_id,
        "#{DYNAMIC_ANNOTATION_PREFIX}issuer"
      )
    )
  end
end
