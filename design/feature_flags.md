# Feature Flags

Feature flags enable partially completed or experimental features to be available in the official Conjur releases. [Martin Fowler](https://martinfowler.com/articles/feature-toggles.html) has an excellent article outlining various approaches to leveraging feature flags.

## Functional Overview

For our initial Feature Flag implementation only supports setting flags via environment variables. In the future, we should support feature flags through file-based as well.

### Define a new feature flag

To create a new feature flag, add the feature name to the `feature_flags` array in `config/initializers/feature_flags.rb`.  For example, to create a feature flag for a feature called `Telemetry Endpoint`, add the following:

```ruby
feature_flags = [
  :telemetry_endpoint
]
```
and restart Conjur.

### Gate a feature

After a new flag has been added to the `feature_flags` array, the Telemetry Endpoint is now a valid feature flag. Functionality can be gated with the following:

```ruby
if Rails.configuration.feature_flags.enabled?(:telemetry_endpoint)
  ... # Gated code here
end
```

### Enable a feature

To enable the Telemetry Endpoint feature, set the feature environment variable flag:

```sh
CONJUR_FEATURE_TELEMETRY_ENDPOINT_ENABLED=true
```

and restart Conjur to pick up the new flag setting.
