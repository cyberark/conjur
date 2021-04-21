# Conjur Metrics and Monitoring

## Background

Conjur metrics provide a data source useful in the operation of a Conjur secrets
management solution to enable:

- Data-driven auto-scaling
- System utilization
- Early problem detection

It is already possible to monitor a Conjur system through proxy measures, for
example CPU and memory utilization. It is also possible to extract some measures
from Conjur by parsing the Conjur server logs. However, these require both effort
and interpretation from the operator to use. By providing application-specific
metrics directly from the Conjur server, Conjur server operators are better
equipped to make data-driven operations decisions.

## Proposed solution overview

- Gather Conjur-specific metrics in the OSS server application. These include:
  
  - API call response codes and durations for:
    - Secrets retrieval
    - Authentication
    - Loading policy
    - Host Factories ??

  - Count of policy resources (e.g. hosts, secrets)

- Export metrics in the [Prometheus metric export format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md)
  at the `/metrics` API endpoint.

## Suggestions for additional system metrics to collect

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

Effective Conjur Secrets Manager monitoring should include the following reports:

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
