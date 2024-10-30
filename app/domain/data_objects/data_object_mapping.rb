# frozen_string_literal: true

module DataObjects
  #
  # This Mapper provides functions for extracting Resource and Role
  # row elements from policy schema results into sets of Conjur primitives
  # related by a common resource_id value.  These results are an intermediate
  # data product, a step in the process of being further transformed into DTOs
  # by the DataObjects::DTOFactory.
  # See the Policy Dry Run v2 Solution Design for a full presentation.
  #
  class Mapper
    def self.map_roles(diff_data)
      items = {}

      role_types = %w[user group host layer policy]

      # Find all "roles" and put them into the items list

      diff_data[:resources].each do |obj|
        resource_type = obj[:resource_id].split(':')[1]
        next unless role_types.include?(resource_type)

        items[obj[:resource_id]] = obj.clone
      end

      # Now map attributes, such as annotations, role_memberships, credentials,
      # permissions, by item.

      # [schema_attribute, primitive_attribute, primitive_id]
      mapping_keys = [
        %i[annotations annotations resource_id],
        %i[permissions permissions role_id],
        %i[credentials credentials role_id],
        %i[role_memberships members role_id],
        %i[role_memberships memberships member_id]
      ]

      # We are mapping schema_attributes (reported by diff),
      # to Conjur primitive_attributes (grouped by PRIMITIVE_IDs)

      mapping_keys.each do |map|
        schema_attribute = map[0]
        primitive_attribute = map[1]
        primitive_id = map[2]

        # Traverse the schema_attribute blocks produced by Diff,
        # looking for primitive_attributes to bundle with their matching Items:

        diff_data[schema_attribute].each do |obj|
          # Got a primitive Item already with that attribute?
          id = obj[primitive_id]
          next unless items.key?(id)

          # Yup, insert the new row of attribute(s) into that Item
          items[id][primitive_attribute] ||= []
          items[id][primitive_attribute] << obj
        end
      end

      items
    end

    def self.map_resources(diff_data)
      items = {}

      resource_types = %w[variable webservice]

      diff_data[:resources].each do |obj|
        resource_type = obj[:resource_id].split(':')[1]
        next unless resource_types.include?(resource_type)

        items[obj[:resource_id]] = obj.clone
      end

      # [schema_attribute, primitive_attribute, primitive_id]
      mapping_keys = [
        %i[annotations annotations resource_id],
        %i[permissions permitted resource_id]
      ]

      mapping_keys.each do |map|
        schema_attribute = map[0]
        primitive_attribute = map[1]
        primitive_id = map[2]

        diff_data[schema_attribute].each do |obj|
          id = obj[primitive_id]
          next unless items.key?(id)

          items[id][primitive_attribute] ||= []
          items[id][primitive_attribute] << obj
        end
      end
      items
    end
  end
end
