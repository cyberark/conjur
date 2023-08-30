# frozen_string_literal: true

class Authenticator
  class << self
    def jwt
      authn_jwt_prefix = "webservice:conjur/authn-jwt/"
      resources_with_authenticator_configs = "SELECT resource_id, enabled
                                              FROM authenticator_configs"

      # join between 3 tables : authn_configs, resources, permissions
      # for getting resource_id, list of permissions for each resource_id and enabled
      # if there is no record_id in authn_configs -> enabled will be false
      # also, we will select resource_id only if it contains authn_jwt_prefix
      # and he have only two "/" character - which means it is only one policy level under authn_jwt
      scope =  Sequel::Model.db.fetch(%{
                                      SELECT "resources"."resource_id",
                                      jsonb_agg(jsonb_build_object(
                                                'privilege', "permissions"."privilege",
                                                'role_id', "permissions"."role_id")) AS "permissions",
                                      COALESCE("authn_configs"."enabled", false) AS "enabled"
                                      FROM "resources"
                                      LEFT JOIN "permissions" ON "resources"."resource_id" = "permissions"."resource_id"
                                      LEFT JOIN
                                        (#{resources_with_authenticator_configs}) AS "authn_configs" ON "resources"."resource_id" = "authn_configs"."resource_id"
                                      WHERE "resources"."resource_id" LIKE '%#{authn_jwt_prefix}%'
                                      GROUP BY "resources"."resource_id", "authn_configs"."enabled";
                                          })
      scope
    end
  end
end