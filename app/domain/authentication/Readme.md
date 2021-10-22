# Building Authenticators

## Overview

Coming soon

## Details

### Adding Validation

Host annotations are commonly used to map a Conjur Host to a remote environments identity attributes. For example:

```yml
# Authn-K8s host
- !host
  id: my-k8s-host
  annotations:
    authn-k8s/namespace: test-app-namespace
    authn-k8s/service-account: test-app-sa

# Authn-Azure host
- !host
  id: my-azure-host
  annotations:
    authn-azure/subscription-id: test-app-subscription-id
    authn-azure/resource-group: test-app-resource-group
```

Host Annotation Validation can be added to any authenticator with two steps:

1. Add an `authn-type` annotation to the host. The annotation value is a lower-case string of the annotation name.  For example:
    ```yml
    # Authn-K8s host
    - !host
      id: my-k8s-host
      annotations:
        authn-type: authn-k8s
        authn-k8s/namespace: test-app-namespace
        authn-k8s/service-account: test-app-sa

    # Authn-Azure host
    - !host
      id: my-azure-host
      annotations:
        authn-type: authn-azure
        authn-azure/subscription-id: test-app-subscription-id
        authn-azure/resource-group: test-app-resource-group
    ```
1. Add a `Validations` class in the authenticator with a `validate_host` method:
    ```ruby
    module Authentication
      module <Authenticator Namespace>
        class Validations

          # The `annotations` arguement is a hash of the host's
          # annotations prefixed with the authenticator name.
          # [Returns] If there are errors in the schema, the error
          # messages should be returned in an array.
          def validate_host(annotations)
          end

        end
      end
    end
    ```
