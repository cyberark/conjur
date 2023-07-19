module Monitoring
  module Metrics
    OPERATIONS = [
      # AccountsApi (undocumented)
      {
        method: "POST",
        pattern: %r{^(/accounts)$},
        operation: "createAccount"
      },
      {
        method: "GET",
        pattern: %r{^(/accounts)$},
        operation: "getAccounts"
      },
      {
        method: "DELETE",
        pattern: %r{^(/accounts)(/[^/]+)$},
        operation: "deleteAccount"
      },

      # AuthenticationApi
      {
        method: "PUT",
        pattern: %r{^(/authn)(/[^/]+)(/password)$},
        operation: "changePassword"
      },
      {
        method: "PATCH",
        pattern: %r{^(/authn-)([^/]+)(/[^/]+){2,3}$},
        operation: "enableAuthenticatorInstance"
      },
      {
        method: "GET",
        pattern: %r{^(/authn)(/[^/]+)(/login)$},
        operation: "getAPIKey"
      },
      {
        method: "GET",
        pattern: %r{^(/authn-ldap)(/[^/]+){2}(/login)$},
        operation: "getAPIKeyViaLDAP"
      },
      {
        method: "POST",
        pattern: %r{^(/authn)(/[^/]+){2}(/authenticate)$},
        operation: "getAccessToken"
      },
      {
        method: "POST",
        pattern: %r{^(/authn-iam)(/[^/]+){3}(/authenticate)$},
        operation: "getAccessTokenViaAWS"
      },
      {
        method: "POST",
        pattern: %r{^(/authn-azure)(/[^/]+){3}(/authenticate)$},
        operation: "getAccessTokenViaAzure"
      },
      {
        method: "POST",
        pattern: %r{^(/authn-gcp)(/[^/]+)(/authenticate)$},
        operation: "getAccessTokenViaGCP"
      },
      {
        method: "POST",
        pattern: %r{^(/authn-k8s)(/[^/]+){3}(/authenticate)$},
        operation: "getAccessTokenViaKubernetes"
      },
      {
        method: "POST",
        pattern: %r{^(/authn-ldap)(/[^/]+){3}(/authenticate)$},
        operation: "getAccessTokenViaLDAP"
      },
      {
        method: "POST",
        pattern: %r{^(/authn-oidc)(/[^/]+){2}(/authenticate)$},
        operation: "getAccessTokenViaOIDC"
      },
      {
        method: "POST",
        pattern: %r{^(/authn-jwt)(/[^/]+){2,3}(/authenticate)$},
        operation: "getAccessTokenViaJWT"
      },
      {
        method: "POST",
        pattern: %r{^(/authn-k8s)(/[^/]+)(/inject_client_cert)$},
        operation: "k8sInjectClientCert"
      },
      {
        method: "PUT",
        pattern: %r{^(/authn)(/[^/]+)(/api_key)$},
        operation: "rotateAPIKey"
      },

      # CertificateAuthorityApi
      {
        method: "POST",
        pattern: %r{^(/ca)(/[^/]+){2}(/sign)$},
        operation: "sign"
      },

      # HostFactoryApi
      {
        method: "POST",
        pattern: %r{^(/host_factories/hosts)$},
        operation: "createHost"
      },
      {
        method: "POST",
        pattern: %r{^(/host_factory_tokens)$},
        operation: "createToken"
      },
      {
        method: "DELETE",
        pattern: %r{^(/host_factory_tokens)(/[^/]+)$},
        operation: "revokeToken"
      },

      # MetricsApi
      {
        method: "GET",
        pattern: %r{^(/metrics)$},
        operation: "getMetrics"
      },

      # PoliciesApi
      {
        method: "POST",
        pattern: %r{^(/policies)(/[^/]+){2,3}(/.*)$},
        operation: "loadPolicy"
      },
      {
        method: "PUT",
        pattern: %r{^(/policies)(/[^/]+){2,3}(/.*)$},
        operation: "replacePolicy"
      },
      {
        method: "PATCH",
        pattern: %r{^(/policies)(/[^/]+){2,3}(/.*)$},
        operation: "updatePolicy"
      },

      # PublicKeysApi
      {
        method: "GET",
        pattern: %r{^(/public_keys)(/[^/]+){3}$},
        operation: "showPublicKeys"
      },

      # ResourcesApi
      {
        method: "GET",
        pattern: %r{^(/resources)(/[^/]+){3}(/.*)$},
        operation: "showResource"
      },
      {
        method: "GET",
        pattern: %r{^(/resources)(/[^/]+){1}$},
        operation: "showResourcesForAccount"
      },
      {
        method: "GET",
        pattern: %r{^(/resources$)},
        operation: "showResourcesForAllAccounts"
      },
      {
        method: "GET",
        pattern: %r{^(/resources)(/[^/]+){2}$},
        operation: "showResourcesForKind"
      },

      # RolesApi
      {
        method: "POST",
        pattern: %r{^(/roles)(/[^/]+){3}$},
        operation: "addMemberToRole"
      },
      {
        method: "DELETE",
        pattern: %r{^(/roles)(/[^/]+){3}$},
        operation: "removeMemberFromRole"
      },
      {
        method: "GET",
        pattern: %r{^(/roles)(/[^/]+){3}$},
        operation: "showRole"
      },

      # SecretsApi
      {
        method: "POST",
        pattern: %r{^(/secrets)(/[^/]+){2}(/.*)$},
        operation: "createSecret"
      },
      {
        method: "GET",
        pattern: %r{^(/secrets)(/[^/]+){3}$},
        operation: "getSecret"
      },
      {
        method: "GET",
        pattern: %r{^(/secrets)$},
        operation: "getSecrets"
      },

      # StatusApi
      {
        method: "GET",
        pattern: %r{^(/authenticators)$},
        operation: "getAuthenticators"
      },
      {
        method: "GET",
        pattern: %r{^(/authn-gcp)(/[^/]+)(/status)$},
        operation: "getGCPAuthenticatorStatus"
      },
      {
        method: "GET",
        pattern: %r{^(/authn-)([^/]+)(/[^/]+){2}(/status)$},
        operation: "getServiceAuthenticatorStatus"
      },
      {
        method: "GET",
        pattern: %r{^(/whoami)$},
        operation: "whoAmI"
      }
    ].freeze
  end
end
