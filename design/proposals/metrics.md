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
- Export metrics in the [Prometheus metric export
  format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md)
  at the `/metrics` API endpoint.
- [Prometheus](https://prometheus.io/) is used to scrape, aggregate and store
  metrics. It can also provide basic visualization.
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

**Conjur HTTP Requests**

HTTP requests into Conjur.

- Metrics
  - `conjur_http_server_requests_total`: Total number of HTTP requests as
    count. 
  - `conjur_http_server_request_duration_seconds`: Duration of HTTP requests as
    gauge in seconds.
- Labels
  - `code`: HTTP status code, such as `200` or `301`.
  - `operation`: The Open API Spec `operationId` for each requested endpoint.

*Note*: Some may noticed the absence of `path` in the labels above. This is an
intentional design choice, given our extensive use of path parameters with
sensitive values.

**Conjur Custom Resources**

Resources managed by Conjur (i.e. roles, resources, hosts, etc).

- Metrics
  - `conjur_resource_count`: Total count of resources stored by Conjur.
- Labels
  - `kind`: Resource type, such as `layer` or `policy`.

**PostgreSQL**

Postgres activity and usage metrics.

For details and metrics, see:
[prometheus-community/postgres_exporter](https://github.com/prometheus-community/postgres_exporter).

**Container Host System Resources**

System resource usage on the container host system.

For metrics, see
[prometheus/node_exporter](https://github.com/prometheus/node_exporter).

## Quick Start

Using Docker Compose, it's easy to start a local environment to experience and
play with metrics in Conjur OSS.

### Start All Services

1. Clone the `conjur` repo.
2. `cd` into `dev` directory.
3. Run `./start --metrics` to kickoff Docker Compose with the correct target.
4. After the script successfully executes, you'll be dropped into the Conjur
  container.  Run `conjurctl server` to start the server.

### Load Sample Data

1. Open a new terminal session.
2. `cd` into `dev` directory in the `conjur` repo.
3. Run `./cli exec` to create a session in the server container.
4. Run `bundle exec cucumber -p api cucumber/api/features` to execute some unit
  tests, which will create some sample data.

### Graphs!

Prometheus is now running and can be visited in your browser at
http://localhost:9090/.  No authentication is needed.  The UI simple and
streamlined.  If you want view/graph some metrics, copy/paste some of the
samples farther down in this doc.

Also, Grafana is now running and can be visited in your browser at
http://localhost:2345/.  The username and password are both `admin`.  You'll be
asked to change it upon first login; feel free to use whatever you want. To see
the Conjur dashboard, go to "Dashboards" > "Manage" > "Conjur Dashboard".

## Future Work

### User Value, Architecture and Design

First and foremost, this work needs to be funded/prioritized as a standard
project and run through our SDLC.  As it stands, this is a proof of concept
that demonstrates what is possible with a relatively modest investment.

To start, PM/PO will need to very clearly identify the value of metrics to
users and customers.  What should they be monitoring?  What values does that
bring their product UX?  As mentioned at the top, there are many possibilities:

* Current Conjur API usage and usage over time to inform capacity provisioning.
* Detect macro issues through aggregated analysis of response codes by API,
  authentication method, and other TBD dimensions.
* Track disk usage over time and alert on low thresholds to ensure logs and audit
  do not fill the disk.
* View DB connection counts and CPU/RAM to ensure that it has appropriate system
  resources for the load.

Additionally, the architecture and implementation need to be revisited.
Choices made during this POC may not be the best ones moving forward.  Some
possible topics:

* Is using `ActiveSupport::Notifications` the right choice for instrumenting
  custom metrics, such as resource counts?  Are they sufficiently performant?
* HTTPS API requests are manually tagged using Open API Spec operations.  Is
  there way to automate this or avoid this duplicated content?
* There is no testing at the moment.  How best could metric gathering be
  tested?  And how can this instrumentation support performance tests?
* Did we make the correct security choices with what the metrics expose?  And
  does the `/metrics` endpoint need authentication (for comparison, `/health`
  and `/info` in enterprise do not)?
* For Conjur OSS, we can really only ship Conjur instrumentation. How can we
  best help users instrument other components on their own (i.e. Nginx, PG,
  etc)?  Can we provide Helm charts to help?

### Instrumenting Other Systems/Resources 

When using Conjur OSS, there are additional systems that are a part of the secrets
manager solution and should also be monitored. These include:

- **Nginx API Gateway**

    Nginx is used as an API gateway for Conjur and there is a Lua library that
    can expose an endpoint for Prometheus to scrape.  See:
    [knyar/nginx-lua-prometheus](https://github.com/knyar/nginx-lua-prometheus).

- **Container Platform/Orchestrator**

    If deployed in Kubernetes, the [Prometheus metrics directly from
    k8s](https://kubernetes.io/docs/concepts/cluster-administration/system-metrics/)
    can be used to monitor orchestration and system-level utilization.

Moreover, Conjur Enterprise has additional systems that can be easily instrumented:

- **etcd Cluster Management**

  etcd supports Prometheus out of the box!  See: [docs on
  metrics](https://etcd.io/docs/v3.4/metrics/).

- **Syslog-NG Log Aggregation**

  See: [related blog](https://www.syslog-ng.com/community/b/blog/posts/prometheus-syslog-ng-exporter).

## Examples of Metrics Monitoring

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
    (
      sum(
        rate(
          conjur_http_server_request_duration_seconds_sum{path=~"^/secrets.*$"}[5m])) / sum(rate(conjur_http_server_request_duration_seconds_count{path=~"^/secrets.*$"}[5m]))) * 1000
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

- Number of active Conjur resources (e.g. Users, Secrets)

    Example Prometheus query:

    ```
    conjur_resource_count
    ```

- CPU Usage (Percent) (using `node_exporter` metrics)

    Example Prometheus query:

    ```
    100 - (avg by (instance) (rate(node_cpu_seconds_total{job="conjur",mode="idle"}[1m])) * 100)
    ```

- Memory Usage (Percent) (using `node_exporter` metrics)

    Example Prometheus query:

    ```
    100 * (1 - ((avg_over_time(node_memory_MemFree_bytes[24h]) + avg_over_time(node_memory_Cached_bytes[24h]) + avg_over_time(node_memory_Buffers_bytes[24h])) / avg_over_time(node_memory_MemTotal_bytes[24h])))
    ```

## Open questions

- How to authenticate and authorize the metrics endpoint?

- Can we provide suggestions for using these metrics for auto-scaling?

- How do metrics fit into Conjur Enterprise?
