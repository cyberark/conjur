# Conjur Metrics and Monitoring

## Background

Quantitative metrics provide a data source useful in the operation of a Conjur
secrets management solution to enable:

- Data-driven auto-scaling
- System utilization analysis
- Early problem detection
- Application health dashboards

It is already possible to monitor a Conjur system through external measures,
for example CPU and memory utilization through a VM or container platform. It
is also possible to extract some metrics from Conjur by parsing and counting
the Conjur server logs. However, these require both effort and interpretation
from the operator to use. By providing application-specific metrics directly
from the Conjur server, Conjur server operators are better equipped to make
data-driven operation decisions.

## Solution Overview

- Gather Conjur-specific metrics in the OSS server application. These include:
  - API call response codes and durations for:
    - Secrets retrieval
    - Authentication
    - Loading policy
    - Host Factories ??
  - Current count of policy resources (e.g. hosts, secrets)
- Export metrics in the [Prometheus metric export format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md)
  at the `/metrics` API endpoint.
- [Prometheus](https://prometheus.io/) is used to scrape, aggregate and store metrics. It can also
  provide basic visualization.
- For more advanced reporting, [Grafana](https://grafana.com/) is used to
  provide insights into Prometheus data.

### Rationale

Prometheus was selected as the metrics standard and collection/analysis tool
for the following reasons:

- Is a mature solution and CNCF graduated project.
- Includes extensive support for coding languages, frameworks and common
  infrastructure tools.
- Can support pushing and pulling metrics.
- Exposes a metrics endpoint that can be used to quickly view metrics with
  `curl` or the like.

OpenTelemetry was also considered, as it provides a different standard for
metrics.  However, we quickly discarded it for the following reasons:

- Is only a CNCF incubating project.
- Was recently created by the merge of OpenTracing and OpenCensus.
- Included standards for metrics and logging are still experimental and are
  likely to change.

## Instrumented Metrics

### Conventions

To start, metrics instrumented in Conjur OSS Secrets Manager must follow the
the [Prometheus best practices](https://prometheus.io/docs/practices/naming/).

Additionally, metrics must also use the following conventions:

- Begin `conjur_` namespace.
- Include a `component` label indicating which part of Conjur emitted the
  metric.

This ensures that our metrics are completely differentiated from other
applications, but also allows identically named metrics across Conjur
components to be easily compared. 

### Metrics

**HTTP Requests**

- Metrics
  - `conjur_http_server_requests_total`: Total number of HTTP requests as
    count. 
  - `conjur_http_server_request_duration_seconds`: Duration of HTTP requests as
    gauge in seconds.
- Labels
  - `method`: HTTP method/verb, such as `get` or `post`.
  - `code`: HTTP status code, such as `200` or `301`.
  - `operation`: The Open API Spec `operationId` for each requested endpoint.

*Note*: Some may noticed the absence of `path` in the labels above. This is an
intentional design choice, given our extensive use of path parameters with sensitive
values.

**Resources**

- Metrics
  - `conjur_resources_total`: Total count of resources stored by Conjur.
- Labels
  - `kind`: Resource type, such as `layer` or `policy`.

### Future Metrics 

When using Conjur OSS, there are additional systems that are a part of the secrets
manager solution and should also be monitored. These include:

- **The Postgres application database**

    The [Prometheus Postgres exporter](https://github.com/prometheus-community/postgres_exporter)
    may be used to provide metrics on the database activity and resources.

- **The nginx API gateway**

    TBD

- **The container host/orchestrator**

    If Conjur is deployed on a single machine Docker host, the Prometheus
    [node exporter](https://github.com/prometheus/node_exporter) can be used
    to gather CPU and other system metrics.

    If deployed in Kubernetes, the [Prometheus metrics directly from k8s](https://kubernetes.io/docs/concepts/cluster-administration/system-metrics/)
    can be used to monitor orchestration and system-level utilization.

## Suggestions for metrics monitoring

Effective Conjur Secrets Manager monitoring include the following reports:

- HTTP Status code counts for Secret retrievals (TODO: Metric name from Conjur)
  
    Example Prometheus query:

    ```
    TODO
    ```

- Successful/Failed secret retrievals over time (TODO: Metric name from Conjur)
  
    Example Prometheus query:

    ```
    TODO
    ```

- Avg secret retrieval duration over time (TODO: Metric name from Conjur)
  
    Example Prometheus query:

    ```
    TODO
    ```

- HTTP Status code counts for Authentications (TODO: Metric name from Conjur)

    Example Prometheus query:

    ```
    TODO
    ```

- Successful/Failed authentications over time (TODO: Metric name from Conjur)
  
    Example Prometheus query:

    ```
    TODO
    ```

- Number of active Secrets (TODO: Metric name from Conjur)

    Example Prometheus query:

    ```
    TODO
    ```

- CPU Usage (TODO: Metric name from node exporter)

    Example Prometheus query:

    ```
    TODO
    ```

- Memory Usage (TODO: Metric name from node exporter)

    Example Prometheus query:

    ```
    TODO
    ```

## Open questions

- How to authenticate and authorize the metrics endpoint?

- Can we provide suggestions for using these metrics for auto-scaling?

- How do metrics fit into Conjur Enterprise?
