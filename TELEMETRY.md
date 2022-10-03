# Conjur Telemetry

Conjur provides a configurable telemetry feature built on
[Prometheus](https://prometheus.io/), which is the preferred open source
monitoring tool for Cloud Native applications. When enabled, it will capture
performance and usage metrics of the running Conjur instance. These metrics are
exposed via a REST endpoint (/metrics) where Prometheus can scrape the data and
archive it as a queryable time series. This increases the observability of a
running Conjur instance and allows for easy integration with popular
visualization and monitoring tools.

## Metrics

This implementation leverages the following supported metric types via the
[Prometheus Ruby client library](https://github.com/prometheus/client_ruby):
| Type | Description
| --- | ----------- |
| counter | A cumulative metric that represents a single monotonically increasing counter whose value can only increase or be reset to zero on restart. |
| gauge | A metric that represents a single numerical value that can arbitrarily go up and down. |
| histogram | A metric which samples observations (usually things like request durations or response sizes) and counts them in configurable buckets. |

See the [Prometheus docs](https://prometheus.io/docs/concepts/metric_types/) for
more on supported metric types.

### Defined Metrics

The following metrics are provided with this implementation and will be captured
by default when telemetry is enabled:
| Metric | Type | Description | Labels\* |
| - | - | - | -|
| conjur_http_server_request_exceptions_total| counter | Total number of exceptions that have occured in Conjur during API requests. | operation, exception, message |
| conjur_http_server_requests_total | counter | Total number of API requests handled Conjur and resulting response codes. | operation, code |
| conjur_http_server_request_duration_seconds | histogram | Time series data of API request durations. | operation |
| conjur_server_authenticator | gauge | Number of authenticators installed, configured, and enabled. | type, status |
| conjur_resource_count | counter | Number of resources in the Conjur database. | kind |
| conjur_role_count | counter | Number of roles in the Conjur database. | kind |

\*Labels are the identifiers by which metrics are logically grouped. For example
`conjur_http_server_requests_total` with the labels `operation` and `code` may
appear like so in the metrics registry:

```txt
conjur_http_server_requests_total{code="200",operation="getAccessToken"} 1.0
conjur_http_server_requests_total{code="201",operation="loadPolicy"} 1502.0
conjur_http_server_requests_total{code="409",operation="loadPolicy"} 1498.0
conjur_http_server_requests_total{code="401",operation="loadPolicy"} 327.0
conjur_http_server_requests_total{code="200",operation="getMetrics"} 60.0
conjur_http_server_requests_total{code="401",operation="unknown"} 62.0
```

This registry format is consistent with the [data model for Prometheus
metrics](https://prometheus.io/docs/concepts/data_model/).

## Configuration

### Enabling Metrics Collection

Metrics telemetry is off by default. It can be enabled in the following ways,
consistent with Conjur's usage of [Anyway Config](https://github.com/palkan/anyway_config):

| **Name** | **Type** | **Default** | **Required?** |
|----------|----------|-------------|---------------|
|    CONJUR_TELEMETRY_ENABLED      |    Env variable     |      None      |        No       |
|    telemetry_enabled      |    Key in Config file      |       None      |        No       |

Starting Conjur with either of the above configurations set to `true` will result
in initialization of the telemetry feature.

### Metrics Storage

Metrics are stored in the Prometheus client store, which is to say they are
stored on the volume of the container running Conjur. The default path for this
is `/tmp/prometheus` but a custom path can also be read in from the environment
variable `CONJUR_METRICS_DIR` on initialization.

When Prometheus is running alongside Conjur, it can be configured to
periodically scrape metric values via the `/metrics` endpoint. It will keep a
time series of the configured metrics and store this data in a queryable
[on-disk database](https://prometheus.io/docs/prometheus/latest/storage/). See
[prometheus.yml](https://github.com/cyberark/conjur/dev/files/prometheus/prometheus.yml)
for a sample Prometheus config with Conjur as a scrape target.

## Instrumenting New Metrics

The following represents a high-level pattern which can be replicated to
instrument new Conjur metrics. Since the actual implementation will vary based
on the type of metric, how the pub/sub event should be instrumented, etc. it is
best to review the existing examples and determine the best approach on a
case-by-case basis.

1. Create a metric class under the Monitoring::Metrics module (see
`/lib/monitoring/metrics` for examples)
1. Implement `setup(registry, pubsub)` method
    1. Initialize the metric by setting instance variables defining the metric
    name, description, labels, etc.
    1. Expose the above instance variables via an attribute reader
    1. Register the metric by calling `Metrics.create_metric(self, :type)` where
    type can be `counter`, `gauge`, or `histogram`
1. Implement `update` method to define update behavior
    1. Get the metric from the registry
    1. Determine the label values
    1. Determine and set the metric values
1. Implement a publishing event*
    1. Determine where in the code an event should be triggered which updates
    the metric
    1. Use the PubSub singleton class to instrument the correct event i.e.
    `Monitoring::PubSub.instance.publish('conjur.policy_loaded')`
1. Add the newly-defined metric to Prometheus initializer
(`/config/initializers/prometheus.rb`)

\*Since instrumenting Pub/Sub events may involve modifying existing code, it
should be as unintrusive as possible. For example, the existing metrics use the
following two methods to avoid modifying any Conjur behavior or impacting
performance:

* For HTTP requests - instrument the `conjur.request` from the middleware layer
so it does not require changes to Conjur code
* For Policy loading - instrument the `conjur.policy_loaded` event using an
`after_action` hook, which avoids modifying any controller methods

## Security

Prometheus supports either an unprotected `/metrics` endpoint, or [basic auth
via the scrape
config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config).
For the sake of reducing the burden on developers, it was elected to leave this
endpoint open by handling it in middleware, bypassing authentication
requirements. This was a conscious decision since Conjur already contains other
unprotected endpoints for debugging/status info. None of the metrics data
captured will contain sensitive values or data.

It was also taken into account that production deployments of Conjur are less
likely to leverage this feature, but if they do, there will almost certainly be
a load balancer which can easily be configured to require basic auth on the
`/metrics` endpoint if required.

## Integrations

As mentioned, Prometheus allows for a variety of integrations for monitoring
captured metrics. [Grafana](https://prometheus.io/docs/visualization/grafana/)
provides a popular lightweight option for creating custom dashboards and
visualizing your data based on queries against Prometheus' data store.

[AWS
Cloudwatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/ContainerInsights-Prometheus.html)
also offers a powerful option for aggregating metrics stored in Prometheus and
integrating them into its Container Insights platform in AWS
[ECS](https://aws-otel.github.io/docs/getting-started/container-insights/ecs-prometheus)
or
[EKS](https://aws-otel.github.io/docs/getting-started/container-insights/eks-prometheus)
environments.

Similar options exist for other popular Kubernetes and cloud-monitoring
platforms, such as [Microsoft's Azure
Monitor](https://learn.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-prometheus-integration)
and [Google's Cloud
Monitoring](https://cloud.google.com/stackdriver/docs/managed-prometheus).

## Performance

Benchmarks were taken with and without the Conjur telemetry feature enabled. It
was found that having telemetry enabled had only a negligible impact
(sub-millisecond) on system performance for handling most requests.

By far the most expensive action is policy loading, which triggers an update to
HTTP request metrics as well as resource, role, and authenticator count metrics.
In this case, there was a 2-4% increase in processing time due to the metric
updates having to wait for a DB write to complete before being able to retrieve
the updated metric values.

The full set of benchmarks can be reviewed
[here.](https://gist.github.com/gl-johnson/4b7fdb70a3b671f634731fe07615cedd)
