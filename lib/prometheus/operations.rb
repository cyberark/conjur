module Prometheus
  module Middleware
    OPERATIONS = [
      # AuthenticationApi
      {
        method: "PUT",
        pattern: /^(\/authn)(\/[^\/]+)(\/password)$/,
        operation: "changePassword"
      },
      {
        method: "PATCH",
        pattern: /^(\/authn-)([^\/]+)(\/[^\/]+){2}$/,
        operation: "enableAuthenticatorInstance"
      },
      {
        method: "GET",
        pattern: /^(\/authn)(\/[^\/]+)(\/login)$/,
        operation: "getAPIKey"
      },
      {
        method: "GET",
        pattern: /^(\/authn-ldap)(\/[^\/]+){2}(\/login)$/,
        operation: "getAPIKeyViaLDAP"
      },
      {
        method: "POST",
        pattern: /^(\/authn)(\/[^\/]+){2}(\/authenticate)$/,
        operation: "getAccessToken"
      },
      {
        method: "POST",
        pattern: /^(\/authn-iam)(\/[^\/]+){3}(\/authenticate)$/,
        operation: "getAccessTokenViaAWS"
      },
      {
        method: "POST",
        pattern: /^(\/authn-azure)(\/[^\/]+){3}(\/authenticate)$/,
        operation: "getAccessTokenViaAzure"
      },
      {
        method: "POST",
        pattern: /^(\/authn-gcp)(\/[^\/]+)(\/authenticate)$/,
        operation: "getAccessTokenViaGCP"
      },
      {
        method: "POST",
        pattern: /^(\/authn-k8s)(\/[^\/]+){3}(\/authenticate)$/,
        operation: "getAccessTokenViaKubernetes"
      },
      {
        method: "POST",
        pattern: /^(\/authn-ldap)(\/[^\/]+){3}(\/authenticate)$/,
        operation: "getAccessTokenViaLDAP"
      },
      {
        method: "POST",
        pattern: /^(\/authn-oidc)(\/[^\/]+){2}(\/authenticate)$/,
        operation: "getAccessTokenViaOIDC"
      },
      {
        method: "POST",
        pattern: /^(\/authn-k8s)(\/[^\/]+)(\/inject_client_cert)$/,
        operation: "k8sInjectClientCert"
      },
      {
        method: "PUT",
        pattern: /^(\/authn)(\/[^\/]+)(\/api_key)$/,
        operation: "rotateAPIKey"
      },

      # CertificateAuthorityApi
      {
        method: "POST",
        pattern: /^(\/ca)(\/[^\/]+){2}(\/sign)$/,
        operation: "sign"
      },

      # HostFactoryApi
      {
        method: "POST",
        pattern: /^(\/host_factories\/hosts)$/,
        operation: "createHost"
      },
      {
        method: "POST",
        pattern: /^(\/host_factory_tokens)$/,
        operation: "createToken"
      },
      {
        method: "DELETE",
        pattern: /^(\/host_factory_tokens)(\/[^\/]+)$/,
        operation: "revokeToken"
      },

      # MetricsApi
      {
        method: "GET",
        pattern: /^(\/metrics$)/,
        operation: "getMetrics"
      },

      # PoliciesApi
      {
        method: "POST",
        pattern: /^(\/policies)(\/[^\/]+){3}$/,
        operation: "loadPolicy"
      },
      {
        method: "PUT",
        pattern: /^(\/policies)(\/[^\/]+){3}$/,
        operation: "replacePolicy"
      },
      {
        method: "PATCH",
        pattern: /^(\/policies)(\/[^\/]+){3}$/,
        operation: "updatePolicy"
      },

      # PublicKeysApi
      {
        method: "GET",
        pattern: /^(\/public_keys)(\/[^\/]+){3}$/,
        operation: "showPublicKeys"
      },

      # ResourcesApi
      {
        method: "GET",
        pattern: /^(\/resources)(\/[^\/]+){3}$/,
        operation: "showResource"
      },
      {
        method: "GET",
        pattern: /^(\/resources)(\/[^\/]+){1}$/,
        operation: "showResourcesForAccount"
      },
      {
        method: "GET",
        pattern: /^(\/resources$)/,
        operation: "showResourcesForAllAccounts"
      },
      {
        method: "GET",
        pattern: /^(\/resources)(\/[^\/]+){2}$/,
        operation: "showResourcesForKind"
      },

      # RolesApi
      {
        method: "POST",
        pattern: /^(\/roles)(\/[^\/]+){3}$/,
        operation: "addMemberToRole"
      },
      {
        method: "DELETE",
        pattern: /^(\/roles)(\/[^\/]+){3}$/,
        operation: "removeMemberFromRole"
      },
      {
        method: "GET",
        pattern: /^(\/roles)(\/[^\/]+){3}$/,
        operation: "showRole"
      },

      # SecretsApi
      {
        method: "POST",
        pattern: /^(\/secrets$)/,
        operation: "createSecret"
      },
      {
        method: "GET",
        pattern: /^(\/secrets)(\/[^\/]+){3}$/,
        operation: "getSecret"
      },
      {
        method: "GET",
        pattern: /^(\/secrets$)/,
        operation: "getSecrets"
      },

      # StatusApi
      {
        method: "GET",
        pattern: /^(\/authenticators$)/,
        operation: "getAuthenticators"
      },
      {
        method: "GET",
        pattern: /^(\/authn-gcp)(\/[^\/]+)(\/status)$/,
        operation: "getGCPAuthenticatorStatus"
      },
      {
        method: "GET",
        pattern: /^(\/authn-)([^\/]+)(\/[^\/]+){2}(\/status)$/,
        operation: "getServiceAuthenticatorStatus"
      },
      {
        method: "GET",
        pattern: /^(\/whoami$)/,
        operation: "whoAmI"
      },
    ]
  end
end
