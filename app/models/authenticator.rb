# frozen_string_literal: true

class Authenticator
  class << self

    def get_property(id)
      begin
        record = Secret.where(:resource_id.like(id)).last.value
        record
      rescue
        ''
      end
    end
    def jwt
      authn_jwt_regex = "webservice:conjur/authn-jwt/[^/]+$" # valid : conjur/authn-jwt/myVendor, not valid : conjur/authn-jwt/myVendor/status
      variable_jwt_prefix = "variable:conjur/authn-jwt/"
      resources_with_authenticator_configs = "SELECT resource_id, enabled
                                              FROM authenticator_configs"

      # # join between 3 tables : authn_configs, resources, permissions
      # # for getting resource_id, list of permissions for each resource_id and enabled
      # # if there is no record_id in authn_configs -> enabled will be false
      # # also, we will select resource_id only if it contains authn_jwt_prefix
      shared_properties =  "SELECT resources.resource_id,
                           jsonb_agg(jsonb_build_object(
                               'privilege', permissions.privilege,
                               'role_id', permissions.role_id)) AS permissions,
                           COALESCE(authn_configs.enabled, false) AS enabled
                          FROM resources
                          LEFT JOIN permissions ON resources.resource_id = permissions.resource_id
                          LEFT JOIN
                            (#{resources_with_authenticator_configs}) AS authn_configs ON resources.resource_id = authn_configs.resource_id
                          WHERE resources.resource_id ~ '#{authn_jwt_regex}'
                          GROUP BY resources.resource_id, authn_configs.enabled"

      # extract all properties (secrets) that belongs to some authn-jwt
      # on theirs latest version
      unique_properties =  "SELECT
                            r.resource_id AS property_id,
                            COALESCE(s.version, 1) AS version
                            FROM resources r
                            LEFT JOIN (
                                SELECT
                                    resource_id,
                                    MAX(version) AS max_version
                                FROM secrets
                                GROUP BY
                                    resource_id
                            ) subquery ON r.resource_id = subquery.resource_id
                            LEFT JOIN secrets s ON r.resource_id = s.resource_id AND subquery.max_version = s.version
                            WHERE r.resource_id LIKE '%#{variable_jwt_prefix}%'"

      # split_part(Shared.resource_id, '/', 3) = split_part(UniqueProps.property_id, '/', 3)
      # explanation : each resource_id has some UniqueProps.property_id , we want to join by the following format
      # cucumber:variable:conjur/authn-jwt/X/Y == cucumber:webservice:conjur/authn-jwt/X
      # conjur/authn-jwt/X --> is the shared part to be joined by
      scope = Sequel::Model.db.fetch(%{
                            WITH Shared AS (
                              #{shared_properties}
                            ),
                            UniqueProps AS (
                              #{unique_properties}
                            )
                            SELECT
                              Shared.resource_id,
                              Shared.permissions,
                              Shared.enabled,
                              jsonb_agg(jsonb_build_object(
                                'property_id', UniqueProps.property_id)) AS claims
                            FROM Shared
                            LEFT JOIN UniqueProps ON split_part(Shared.resource_id, '/', 3) = split_part(UniqueProps.property_id, '/', 3)
                            GROUP BY Shared.resource_id, Shared.permissions, Shared.enabled
                            ORDER BY Shared.resource_id
                          })
      scope
    end
  end
end