# Solution Design - Conjur Metrics Telemetry

[//]: # "General notes:"
[//]: # "1. Design should be graphical-based and table-based - avoid long text explanations"
[//]: # "2. Design documents should not be updated after implementation"
[//]: # "3. Design decisions should be made before writing this document, and as such this document should not include options / choices"


## Table of Contents
[//]: # "You can use this tool to generate a TOC - https://ecotrust-canada.github.io/markdown-toc/"

- [Solution Design - Conjur Metrics Telemetry](#solution-design---conjur-metrics-telemetry)
  - [Table of Contents](#table-of-contents)
  - [Glossary](#glossary)
  - [Useful Links](#useful-links)
  - [Background](#background)
    - [Conjur Metrics Telemetry](#conjur-metrics-telemetry)
  - [Issue Description](#issue-description)
  - [Solution](#solution)
    - [Solution overview](#solution-overview)
    - [Rationale](#rationale)
    - [Instrumented Metrics](#instrumented-metrics)
      - [Conventions](#conventions)
      - [Metrics](#metrics)
        - [Conjur HTTP Requests](#conjur-http-requests)
        - [Conjur Policy Resources](#conjur-policy-resources)
        - [Conjur Authenticators](#conjur-authenticators)
    - [User Interface](#user-interface)
  - [Design](#design)
    - [Gathering metrics and exposing the `/metrics` endpoint](#gathering-metrics-and-exposing-the---metrics--endpoint)
    - [Code design for instrumentation](#code-design-for-instrumentation)
      - [Request instrumentation](#request-instrumentation)
      - [Intra-request instrumentation](#intra-request-instrumentation)
    - [Flow Diagrams](#flow-diagrams)
    - [Class / Component Diagrams](#class---component-diagrams)
      - [Class / Details](#class---details)
    - [Sequence Diagrams](#sequence-diagrams)
    - [External Interfaces](#external-interfaces)
  - [Performance](#performance)
  - [Backwards Compatibility](#backwards-compatibility)
  - [Affected Components](#affected-components)
  - [Work in Parallel](#work-in-parallel)
  - [Test Plan](#test-plan)
    - [Test Environments](#test-environments)
    - [Test Assumptions](#test-assumptions)
    - [Out of Scope](#out-of-scope)
    - [Prerequisites](#prerequisites)
    - [Test Cases (Including Performance)](#test-cases--including-performance-)
      - [Functional Tests](#functional-tests)
      - [Security Tests](#security-tests)
      - [Error Handling / Recovery / Supportability tests](#error-handling---recovery---supportability-tests)
      - [Performance Tests](#performance-tests)
  - [Logs](#logs)
  - [Documentation](#documentation)
  - [Security](#security)
  - [Infrastructure](#infrastructure)
  - [Audit](#audit)
  - [Stories](#stories)
    - [Add the Prometheus scrape target endpoint to Conjur](#add-the-prometheus-scrape-target-endpoint-to-conjur)
    - [Add metrics collection to Conjur](#add-metrics-collection-to-conjur)
    - [Metrics collection is configurable](#metrics-collection-is-configurable)
    - [Expose REST API metrics on Prometheus scrape target](#expose-rest-api-metrics-on-prometheus-scrape-target)
    - [Expose policy resource scount metrics on Prometheus scrape target](#expose-policy-resource-scount-metrics-on-prometheus-scrape-target)
    - [Expose policy roles counts metrics on Prometheus scrape target](#expose-policy-roles-counts-metrics-on-prometheus-scrape-target)
    - [Expose authenticators counts metrics on Prometheus scrape target](#expose-authenticators-counts-metrics-on-prometheus-scrape-target)
    - [Performance testing of Conjur metrics](#performance-testing-of-conjur-metrics)
    - [Documentation for Conjur metrics](#documentation-for-conjur-metrics)
    - [Quick-start for consuming Conjur metrics](#quick-start-for-consuming-conjur-metrics)
  - [Open Questions](#open-questions)
  - [Definition of Done](#definition-of-done)
  - [Solution Review](#solution-review)

## Glossary
[//]: # "Describe terms that will be used throughout the design"
[//]: # "You can use this tool to generate a table - https://www.tablesgenerator.com/markdown_tables#"

| **Term** | **Description** |
|----------|-----------------|
|          |                 |
|          |                 |

## Useful Links
[//]: # "Add links that may be useful for the reader"

|  **Name**   | **Link** |
|-------------|----------|
| Feature Doc |    [link](https://cyberark365.sharepoint.com/:w:/r/sites/Conjur/Shared%20Documents/SDLC/Projects/Conjur%20OSS/Conjur%20Telemetry/Feature%20Doc%20-%20Conjur%20Telemetry.docx?d=w7bf6e887888f4ba28c1ca72423af59eb&csf=1&web=1&e=evywen)  (private)    |

## Background
[//]: # "Give relevant background for the designed feature. What is the motivation for this solution?"
### Conjur Metrics Telemetry

The key motivation behind this effort, which is a first step in a wider effort, is to improve the observability of Conjur. This particular effort concerns itself with enabling internal Conjur admins to easily collect time-series metrics from Conjur in order to better observe the service and manage its operation. As Conjur does not, at the time of writing, expose any metrics, this is a green field solution that is relatively easy to implement with common libraries and tooling. It provides foundational insights in a non-distruptive way and paves way for later pursuing progress on other elements of telemetry such as structured logging and tracing.

This effort is building upon work from an earlier R&D hackathon.

## Issue Description
[//]: # "Elaborate on the issue you are writing a solution for"

Time-series metrics provide a data source useful in the operation of a Conjur secrets management solution to enable:

+ Data-driven auto-scaling
+ System utilization analysis
+ Early problem detection
+ Application health dashboards

It is already possible to monitor a Conjur system through external measures, for example CPU and memory utilization through a VM or container platform. It is also possible to extract some metrics from Conjur by parsing and counting the Conjur server logs. However, these require both effort and interpretation from the operator to use. By providing application-specific metrics directly from the Conjur server, Conjur server operators are better equipped to make data-driven operation decisions.

## Solution

[//]: # "Elaborate on the solution you are suggesting in this page. Address the functional requirements and the non functional requirements that this solution is addressing. If there are a few options considered for the solution, mention them and explain why the actual solution was chosen over them. Add an execution plan when relevant. It doesn't have to be a full breakdown of the feature, but just a recommendation to how the solution should be approached."

### Solution overview

- Gather Conjur-specific metrics in the OSS server application. These include:
  - API call response codes and durations (measured to only take into account the impact of all the Rack middleware components, including Rails). API calls identified by their [Open API Spec `operationId`]](https://github.com/cyberark/conjur-openapi-spec/blob/main/spec/authentication.yml#L158).
  - Current count of policy resources (e.g. hosts, secrets)
  - Current count of configured authenticators
- Conjur service instance exposes metrics in the [Prometheus metric export
  format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md)
  at the `/metrics` API endpoint. This allows time-series collection via a pull model over HTTP.
  ![image](https://user-images.githubusercontent.com/8653164/145210046-da9a3af4-a7be-4fc0-89b4-4af56b62691e.png)
  - [Prometheus](https://prometheus.io/) can be used to scrape, aggregate and store
    metrics. It can also provide basic visualization.
  - For more advanced reporting, solutions like [Grafana](https://grafana.com/) or [Cloudwatch](https://aws.amazon.com/blogs/containers/amazon-cloudwatch-prometheus-metrics-ga/) can be used to
    provide insights into Prometheus data.
- The performance impact of the instrumentation is known and acceptable.
- Instrumentation is disabled by default and can be enabled via the new configuration system.
- Documentation for integrating the metrics endpoint with Prometheus, including some suggested graphs to watch.
- Support for the Conjur Server OSS is tested, verified and documented.

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

### Instrumented Metrics

#### Conventions

To start, metrics instrumented in Conjur OSS Secrets Manager must follow the
the [Prometheus best practices](https://prometheus.io/docs/practices/naming/).

Additionally, metrics must also use the following conventions:

- Begin `conjur_` namespace.
- Include a `component` label indicating which part of Conjur emitted the
  metric.
- For the Conjur app itself, the component should be server, thus conjur_server_<metric>.

This ensures that our metrics are completely differentiated from other
applications, but also allows identically named metrics across Conjur
components to be easily compared.

#### Metrics

##### Conjur HTTP Requests

HTTP requests into Conjur.

- Metrics
  - `conjur_http_server_requests_total`: Total number of HTTP requests as
    count.
  - `conjur_http_server_request_duration_seconds`: Duration of HTTP requests as
    gauge in seconds. Measured to only take into account the impact of all the Rack middleware components, including Rails.
- Labels
  - `code`: HTTP status code, such as `200` or `301`.
  - `operation`: The [Open API Spec `operationId`](https://github.com/cyberark/conjur-openapi-spec/blob/main/spec/authentication.yml#L158) for each requested endpoint.

*Note*: Some may noticed the absence of `path` in the labels above. This is an
intentional design choice, given our extensive use of path parameters with
sensitive values.


##### Conjur Policy Resources

Resources managed by Conjur (i.e. roles, resources, hosts, etc).

- Metrics
  - `conjur_server_policy_(roles|resources)`: Total count of particular types of resources stored by Conjur, such as hosts, variables and users.
- Labels
  - `kind`: Resource type.

These resources are potentially modified any time that [policy is loaded](https://github.com/cyberark/conjur/blob/master/app/controllers/policies_controller.rb#L43). For each policy load the counts needs to be determined using the query shown below.
```
kind = ::Sequel.function(:kind, :resource_id)
Resource.group_and_count(kind).each do |record|
  # ...
end
```

NOTE: It might be possible to keep the counts in the database. This would mitigate any concerns about the performance of the group and count query.

##### Conjur Authenticators

- Metrics
  - `conjur_server_authenticators`: Gauge of current total count of configured authenticators within Conjur.
- Labels
  - `type`: The authenticator type: `k8s`, `jwt`, `azure`, etc.
  - `status`: Current status of the authenticator: `configured`, `enabled`.

The configured authenticators are potentially modified whenever the [update action](https://github.com/cyberark/conjur/blob/master/app/domain/authentication/update_authenticator_config.rb) is invoked, it is then that the counts must be [determined](https://github.com/cyberark/conjur/blob/master/app/domain/authentication/installed_authenticators.rb#L23).

### User Interface
[//]: # "Describe user interface (including command structure, inputs/outputs, etc where relevant)"


Metrics telemetry is off by default. It can be enabled in the following ways:

| **Name** | **Type** | **Default** | **Required?** |
|----------|----------|-------------|---------------|
|    CONJUR_TELEMETRY_ENABLED      |    Env variable     |      None      |        No       |
|    telemetry_enabled      |    Key in Config file      |       None      |        No       |

## Design
[//]: # "Add any diagrams, charts and explanations about the design aspect of the solution. Elaborate also about the expected user experience for the feature"

This section details the architecture and implementation details.

### Gathering metrics and exposing the `GET /metrics` endpoint

- `GET /metrics`, the scraping target must be defined on the Conjur HTTP server. Prometheus will periodically consume this endpoint to gather metrics.

[Prometheus client ruby](https://github.com/prometheus/client_ruby) provides a nice and standard API for collecting and exposing metrics (`Prometheus::Client::Formats::Text.marshal(registry)`) in the desired format. It also provide examples of Rack middleware for tracing all HTTP requests ([collector](https://github.com/prometheus/client_ruby/blob/master/lib/prometheus/middleware/collector.rb)) and exposing a metrics HTTP endpoint to be scraped by a Prometheus server ([exporter](https://github.com/prometheus/client_ruby/blob/master/lib/prometheus/middleware/exporter.rb))

For security purposes, Prometheus supports [basic auth](https://prometheus.io/docs/guides/basic-auth/), from Prometheus to the scraping target. We could add support for this within our implementation for convinience, however any production deployment of Conjur will likely use a load balancer which can easily be configured to require basic auth on this endpoint. NOTE that by implementing this internally we can do things like dynamically retrieve the basic auth credentials from Conjur.

### Code design for instrumentation

There are 2 categories of metrics that we are interested in collecting.
1. At the level of entire requests, and generally concerned with the request URL
2. More granular, and concerned with actions taking place deep with any given request cycle

One of the design goals is to decouple the normal operation of Conjur, the collection of metrics and the publishing of metrics.

**The pub/sub pattern** is one way in which this goal can be achieved, we can use pub/sub to bridge the gap between where the metrics are collected and where the metrics are published. A viable option that is native to Rails is `ActiveSupport::Notifications.instrument` , which is synchronous in calling its subscribes when an event is published and would rely on the guarantee that any given subscriber has negligible overhead. It's reassuring that this pub/sub pattern is recommended for decoupling when integrating with this [Rails monitoring solution](https://blog.appoptics.com/monitoring-rails-get-hidden-metrics-rails-app/) out in the wild.


A different implementation of pub/sub has been suggested over at  https://github.com/cyberark/conjur/pull/2446/, using the Gem `rails_semantic_logger`. This has similar benefits to using `ActiveSupport::Notifications` but specifically comes baked in with logs and metrics considerations.  For the goals of this project we do not have sufficient justification to assume this dependency, especially since we don't currently have use for the logs and metrics capabilities.

**The decorator pattern** can be used to separated the normal operation of Conjur from the collection of metrics. This allows us to wrap the normal operation of Conjur and extend it in such a way that the the code for the normal operation lives in a separate place to the code making measurements and publishing to our pub/sub implementation.


#### Request instrumentation

Conjur is a Rails server. Rails has a native way to get visibility into all incoming requests,   Rack middleware. It's essentially the decorator pattern in action. We can define our own Rack midldeware that can wrap around all incoming requests and collect metrics at the granulariy of endpoints.

The Rack middleware currently implemented in the hackathon branch is tied to writing metrics into the Prometheus store. To provide a more flexible option, this middleware could gather request metrics and publish them using `ActiveSupport::Notifications.instrument`.

#### Intra-request instrumentation

Below is an example of using the decorate pattern and the pub sub.

Decorate the controller by extending instance methods, so that when policy loads the extension logic will publish onto the pub/sub.
```
module InstrumentPoliciesController
  private

  def load_policy(action, loader_class, delete_permitted)
    res = nil

    duration = Benchmark.realtime { res = super }

    # TODO: we could also make this logic conditional on configuration, otherwise no-op. However
    # it is unnecessary here because the no-op will be done on the subscription side.
    ActiveSupport::Notifications.instrument("policy_loaded.conjur", duration: duration)

    res
  end
end

class PoliciesController < RestController
  # Decorate the policy controller
  prepend InstrumentPoliciesController

  private

  def load_policy(action, loader_class, delete_permitted)
    # ...
  end
end
```

In a separate file, subscribe to the policy loaded event and update metrics accordingly.
```
# Subscribe to Conjur ActiveSupport events for metric updates

ActiveSupport::Notifications.subscribe("policy_loaded.conjur") do
  # Update the resource counts after policy loads
  update_resource_count_metric(registry)
end
```


### Flow Diagrams
[//]: # "Describe flow of main scenarios in the system. The description should include if / else decisions and loops"

### Class / Component Diagrams
[//]: # "Describe classes that are going to be added /changes and their immediate environment. Non-changed classes may be colored differently"

#### Class / Details
[//]: # "Describe details of each class - to emphasise its main functionality / methods and interactions"

### Sequence Diagrams
[//]: # "Describe main flows in system influenced by this design - using sequence diagram UML"

### External Interfaces
[//]: # "Describe SW interfaces to the blocks / classes that are external to this part of of project"
[//]: # "The description should contain full set of parameters per event, as well as method of interaction (sync / async / REST / GRPC / TCP /..)"

## Performance
[//]: # "Describe potential performance issues that might be raised by the system as well as their mitigations"
[//]: # "How does this solution affect the performance of the product?"

| **Subject** | **Description** | **Issue Mitigation** |
|-------------|-----------------|----------------------|
|      Latency on Requests       |      Metrics are collected in and around the request lifecycle. The act of measuring has the potential to increase the latency of the requests, both at the individual level and over time           |         Performance testing to ensure that the overhead due to metrics remains within reasonable bounds even when load is applied for a reasonably long time like a few minutes.             |

## Backwards Compatibility
[//]: # "How will the design of this solution impact backwards compatibility? Address how you are going to handle backwards compatibility, if necessary"

As Conjur does not, at the time of writing, expose any metrics (or metrics endpoint), this is a green field solution. This means there is no requirement of backwards compatibility within the feature itself. Metrics collection is opt-in and so will be disabled by default.

## Affected Components
[//]: # "List all components that will be affected by your solution"
[//]: # "[Conjur Open Source/Enterprise, clients, integrations, etc.]"
[//]: # "and elaborate on the impacts. This list should include all"
[//]: # "downstream components that will need to be updated to consume"
[//]: # "new releases as these changes are implemented"

This feature affects the **Conjur Open Source** component, which propagates to the **Conjur Enterprise** component. No other components will be affected.

## Work in Parallel
[//]: # "How can we work in parallel for this task? How this can be done effectively without hindering the work of others who are working on different areas of the task."
[//]: # "For example, can we introduce minimal automation to run basic sanity tests to protect the work of others?"

## Test Plan

The components that constitute the implementation of metrics telemetry can be unit-tested. In unit tests we can compare, for any given action, the value registered by prometheus against the base truth. This validates how we are measuring.


### Test Environments
[//]: # "Including build number, platforms etc. Considering the OS and version of PAS (PVWA, CPM), Conjur, Synchronizer etc."

| **Feature** | **OS** | **Version Number** |
|-------------|--------|--------------------|
|      Conjur       |     Linux   |                    |

This feature has no special requirements in terms of environment, there the test environment can be limited to Linux running on Docker.

### Test Assumptions

### Out of Scope

### Prerequisites
[//]: # "List any expected infrastructure requirements here"

### Test Cases (Including Performance)

#### Functional Tests

[//]: # "Fill in the table below to depict the tests that should run to validate your solution"
[//]: # "You can use this tool to generate a table - https://www.tablesgenerator.com/markdown_tables#"

| **Title** | **Given** | **When** | **Then** | **Comment** |
|-----------|-----------|----------|----------|-------------|
|    Register change in policy resources counts       |    An API request is made that modifies policy resources counts     |    Metrics are enabled      |   The current policy resource count should be reflected within the Prometheus store        |             |
|    Register change in authenticator configuration        |    An API request is made that modifies authenticator configuration     |    Metrics are enabled      |   The authenticators count grouped by labels should be reflected within the Prometheus store        |             |
|    Register metrics around HTTP requests        |    An API request is made    |    Metrics are enabled      |   The difference in the HTTP metrics stored in the Prometheus store before and after the request should reflect the API request     |
|    Ignore metrics when not enabled      |    Any API request that modifies values that are typically captured by metrics (policy resouce count, HTTP request metrics etc.)     |    Metrics are not enabled      |   The Prometheus store remains unchanged      |             |


#### Security Tests

[//]: # "Fill in the table below to depict the tests that should run to validate your solution"
[//]: # "You can use this tool to generate a table - https://www.tablesgenerator.com/markdown_tables#"

| **Title** | **Given** | **When** | **Then** | **Comment** |
|-----------|-----------|----------|----------|-------------|
|           |           |          |          |             |
|           |           |          |          |             |

#### Error Handling / Recovery / Supportability tests

[//]: # "Fill in the table below to depict the tests that should run to validate your solution"
[//]: # "You can use this tool to generate a table - https://www.tablesgenerator.com/markdown_tables#"

| **Title** | **Given** | **When** | **Then** | **Comment** |
|-----------|-----------|----------|----------|-------------|
|           |           |          |          |             |
|           |           |          |          |             |

#### Performance Tests

[//]: # "Fill in the table below to depict the tests that should run to validate your solution"
[//]: # "You can use this tool to generate a table - https://www.tablesgenerator.com/markdown_tables#"

Some performance testing tools
1. Artillery https://www.artillery.io/
2. ab
3. vegeta https://github.com/tsenart/vegeta

The overhead for writing metrics into the Prometheus registry is expected to be neglible, since everything is taking place in-memory.
Maintaining resource counts raises concerns about performance. However, if any group and count query can be guaranteed to be low-to-sub millisecond then this can be ignored.

| **Scenario** | **Spec** | **Environment(s)** | **Comments** |
|--------------|----------|--------------------|--------------|
|     Typical load (frequent authentication and secret retrieval, interspersed with load loading)        |     Compare the statistics of the scenario between Conjur with and without metrics collection       |                    |       This test is to ensure that under typical load the cost of collecting metrics is within reasonable bounds      |
|     Typical load on populated database        |    Compare the statistics of the scenario between Conjur with and without metrics collection        |                    |    This test is to ensure that when the database has a lot of policy resources the cost of collecting metrics remains within reasonable bounds        |


## Logs
[//]: # "If the logs are listed in the feature doc, add a link to that section. If not, list them here."
[//]: # "You can use this tool to generate a table - https://www.tablesgenerator.com/markdown_tables#"

Conjur metrics telemetry will produce a limited number of logs to support it's function.

| **Scenario** | **Log message** |
|--------------|-----------------|
|   Startup: Conjur metrics telemetry status           |       Conjur metrics telemetry is [enabled and available at /metrics]|[disabled]          |
|   Contained failure to register metrics telemetry           |      Unable to register <metric> metrics: <reason>            |

## Documentation
[//]: # "Add notes on what should be documented in this solution. Elaborate on where this should be documented, including GitHub READMEs and/or official documentation."

Documentation for Conjur Metrics Telemetry will include:

1. No official, public, documentation. This particular effort is internal facing
2. Internal documentation for configuring Conjur metrics telemetry
3. Internal documentation for integrating Conjur metrics telemetry [with AWS CloudWatch](https://aws.amazon.com/blogs/containers/amazon-cloudwatch-prometheus-metrics-ga/)
4. Source code documentation for adding new metrics (and extending functionality)
5. Short, simple instructions and scripts for running Prometheus with Conjur OSS

## Security
[//]: # "Are there any security issues with your solution? Even if you mentioned them somewhere in the doc it may be convenient for the security architect review to have them centralized here"

| **Security Issue** | **Description** | **Resolution** |
|--------------------|-----------------|----------------|
|       Abuse of the scraping target `GET /metrics`            |       If left public the scraping target could be the subject of abuse.          |      Prometheus supports [basic auth](https://prometheus.io/docs/guides/basic-auth/), from Prometheus to the scraping target. We could add support for this within our implementation for convinience, however any production deployment of Conjur will likely use a load balancer which can easily be configured to require basic auth on this endpoint.          |

## Infrastructure

[//]: # "Does your solution require assistence from the Infrastructure team? Take a moment to elaborate in this section on the types of items that you require and create issues in the ops project: https://github.com/conjurinc/ops/issues. It is best to make these requests as soon as possible as it may require some time to deliver."

## Audit

[//]: # "Does this solution require adding audit logs? Does it affect existing audit logs?"

<!-- | **Name (ID)** | **Description** | **Issued On** |
|---------------|-----------------|---------------|
|               |                 |               |
 -->

It is not intended to modify audit logs in any way.

## Stories

### Add the Prometheus scrape target endpoint to Conjur

Expose GET /metrics endpoint

In the [solution design](https://github.com/cyberark/conjur/blob/040f5041fadf085e47087e4ef8286bc66e72ec74/design/telemetry/metrics_solution_design.md#gathering-metrics-and-exposing-the-get-metrics-endpoint), we have decided to leverage the [Prometheus client gem](https://github.com/prometheus/client_ruby) for this implementation.

We can crib from the hackathon work, here's a link to the diff https://github.com/cyberark/conjur/compare/2021-hackathon-mlee. The general idea is to add a route that responds with the serialized version of the Prometheus client store.

The Prometheus client gem provides a nice API for serializing metrics to the standard format `Prometheus::Client::Formats::Text.marshal(registry)`. It also provides a more comprehensive example of [an exporter Rack middleware](https://github.com/prometheus/client_ruby#rack-middleware) that exposes a scrape target endpoint, looking at the source for this rack middleware you'll notice that this uses `Prometheus::Client::Formats::Text.marshal` and is more [well-rounded in terms of negotiating content types](https://github.com/prometheus/client_ruby/blob/master/lib/prometheus/middleware/exporter.rb#L30).

A/C
- [ ] Create a Prometheus client store
- [ ] Expose the Prometheus client store via the GET /metrics scrape target
- [ ] Add test cases to ensure the scrape target works as expected

### Add metrics collection to Conjur

The solution design [speaks about using the pub/sub pattern](https://github.com/cyberark/conjur/blob/040f5041fadf085e47087e4ef8286bc66e72ec74/design/telemetry/metrics_solution_design.md#code-design-for-instrumentation) to decouple Conjur business logic from metrics collection logic. This issue is about setting up plumbing for metrics collection. In this case we are specifically interested in collecting for Prometheus but the idea is that we should be able to have non-Prometheus subscribers too. Here are define the Prometheus collector which holds the Prometheus client store, supported by a pub/sub mechanism which informs the collector through events about updates that should be to metrics. So there is
1. Pub/sub mechanism based on `ActiveSupport::Notifications`. This should really be a separate entity that can be passed around/dep injected. This pub/sub mechanism is consumed by any entity (e.g. controllers/custom rack middleware) that wants to publish events that will result in metric updates
2. The Prometheus client store that is the internal representation of the metrics gathered throughout the life of the Conjur server. This client store needs to be accessible to the scrape target endpoint!
3. Subscribers on the collector side that (1) carry out any initialization, such as defining the metric and metric type on the store, logic for the metrics they cater to and (2) respond to metric-specific events and convert them into metric updates

A/C
- [ ] Documentation around adding a new metric subscriber
- [ ] Add test cases to ensure that everything works
    - an end to end example of a metrics subscriber that defines some metrics and when events are dispatched this is reflected on the store
    - a test case to ensure that the prometheus store linked to the collector is made available to the exporter

### Metrics collection is configurable

As an environment variable:

`CONJUR_TELEMETRY_ENABLED=true`

In the conjur.conf configuration file:

`telemetry_enabled=true`

As with all configurations, at this time, this must be set for every instance of the Conjur OSS Server.  It’s not replicated across instances.  After making one of the two changes above, simply apply the updated configuration using conjurctl configuration apply (or by restarting the Conjur processes).

At this point, Conjur will be collecting samples and tallying them in memory.  Also, the /metrics endpoint is enabled will no longer report a 404.

A/C
- [ ] Telemetry is disabled by default
- [ ] Telemetry can be enabled/disabled explicitly via configuration file (conjur.conf) or environment variable, see lib/conjur/conjur_config.rb. Variable takes precedence
- [ ] No collection or exporting takes place while telemetry is disabled
- [ ] There are test cases validating behaviors

### Expose REST API metrics on Prometheus scrape target
For this we need to register REST API metrics onto the Prometheus client store. Consult the [solution design](https://github.com/cyberark/conjur/blob/040f5041fadf085e47087e4ef8286bc66e72ec74/design/telemetry/metrics_solution_design.md#conjur-http-requests) for details around the metric metadata. The general idea is to

1. Collect the metrics through custom Rack middleware. The prometheus client gem provides an [example Rack middleware](https://github.com/prometheus/client_ruby/blob/master/lib/prometheus/middleware/collector.rb) for tracing HTTP requests. This idea was used in the hackathon and expanded upon in the POC for the soluition design, so for the implementation we can crib from `lib/prometheus/custom_collector.rb` in the [diff from the POC branch](https://github.com/cyberark/conjur/compare/metrics-poc-kt#diff-963b0f7173b1dd7863e1c623cccdc5e03fba88c1ca33e1d3730ae571da2913ce).
2. Publish an event (e.g. `request.conjur`) with enough data that the subscriber can use to make the metrics updates.
3. The Prometheus subscriber for these metrics will interpret that event and make appropriate metric updates to the store. The act of adding the metrics onto the store, combined with the prior work to setup the Prometheus exporter should result in the metric being present in the scrape target endpoint `GET /metrics`.

NOTE: In the Rack middleware we need to ensure that our measurements take into account all other Rack middleware applied to a request. This means the metrics collection Rack middleware must be [first in the list](https://blog.appoptics.com/monitoring-rails-get-hidden-metrics-rails-app/#:~:text=Note%20that%20the%C2%A0Librato%3A%3ARack%C2%A0middleware%20is%20the%20very%20first%20item%20in%20the%20list%2C%20while%20my%20Rails%20app%20is%20the%20last).

A/C

- [ ] REST API metrics are collected
- [ ] REST API metrics are exposed on the scrape target
- [ ] There are test cases validating this behavior end to end
    + lightweight test: requests made on the REST API are reflected in the response of the scrape target endpoint
    + pub/sub plumbing is unit tested so that when any relevant events are dispatched the expected changes are reflected on the store

### Expose policy resource scount metrics on Prometheus scrape target

NOTE: this is policy **resources**, NOT is policy roles!

For this we need to register policy resources counts metrics onto the Prometheus client store. Consult the [solution design](https://github.com/cyberark/conjur/blob/metrics-solution-design/design/telemetry/metrics_solution_design.md#conjur-policy-resources) for the policy resource count metric definitions. The general idea is to

1. Publish an event (e.g. `conjur_policy_load`) the subscriber can use to make the metrics updates. In this case there really isn't any data for the event to pass along with the event since at policy load time we only know that the policy resouce count has potentially changed, and not what the changes were. This event is published on policy load, which we believes takes place exclusively at [load_policy](https://github.com/cyberark/conjur/blob/metrics-solution-design/app/controllers/policies_controller.rb#L50]) in the PolicyController.
2. The Prometheus subscriber for these metrics will interpret that event and make appropriate metric updates to the store. In this case the subscriber is responsible for determining the latest policy resources counts by [querying the database](https://github.com/cyberark/conjur/blob/metrics-solution-design/design/telemetry/metrics_solution_design.md#conjur-policy-resources).

  The act of adding the metrics onto the store, combined with the prior work to setup the Prometheus exporter should result in the metric being present in the scrape target endpoint `GET /metrics`.

A/C

- [ ] Policy resources counts metrics are collected
- [ ] Policy resources counts are exposed on the scrape target
- [ ] There are test cases validating this behavior end to end
    + lightweight test: make policy updates by invoking the policy endpoints, and ensure that any changes are reflected in the response of the scrape target endpoint
    + pub/sub plumbing is unit tested so that when policy is loaded (1) an event is dispatched, (2) an event dispatched results in the correct subscriber logic running, (3) the subsciber logic grabs the latest policy resources counts and writes them onto the Prometheus store

### Expose policy roles counts metrics on Prometheus scrape target

NOTE: this is policy roles, NOT policy resources!

For this we need to register policy roles counts metrics onto the Prometheus client store. Consult the [solution design](https://github.com/cyberark/conjur/blob/metrics-solution-design/design/telemetry/metrics_solution_design.md#conjur-policy-resources) for the policy roles counts metric definitions. The general idea is to

1. Publish an event (e.g. `conjur_policy_load`) the subscriber can use to make the metrics updates. In this case there really isn't any data for the event to pass along with the event since at policy load time we only know that the policy resouce count has potentially changed, and not what the changes were. This event is published on policy load, which we believes takes place exclusively at [load_policy](https://github.com/cyberark/conjur/blob/metrics-solution-design/app/controllers/policies_controller.rb#L50]) in the PolicyController. NOTE that the method `load_policy` returns `created_roles`, perhaps this can be used to determine avoid unnecessarily querying the database for policy roles counts changes.
2. The Prometheus subscriber for these metrics will interpret that event and make appropriate metric updates to the store. In this case the subscriber is responsible for determining the latest policy roles counts by [querying the database](https://github.com/cyberark/conjur/blob/metrics-solution-design/design/telemetry/metrics_solution_design.md#conjur-policy-resources).

  The act of adding the metrics onto the store, combined with the prior work to setup the Prometheus exporter should result in the metric being present in the scrape target endpoint `GET /metrics`.

A/C

- [ ] Policy roles counts metrics are collected
- [ ] Policy roles counts are exposed on the scrape target
- [ ] There are test cases validating this behavior end to end
    + lightweight test: make policy updates by invoking the policy endpoints, and ensure that any changes are reflected in the response of the scrape target endpoint
    + pub/sub plumbing is unit tested so that when policy is loaded (1) an event is dispatched, (2) an event dispatched results in the correct subscriber logic running, (3) the subsciber logic grabs the latest policy roles counts and writes them onto the Prometheus store

### Expose authenticators counts metrics on Prometheus scrape target

For this we need to register authenticators counts metrics onto the Prometheus client store. Consult the [solution design](https://github.com/cyberark/conjur/blob/metrics-solution-design/design/telemetry/metrics_solution_design.md#conjur-authenticators) for the authenticators counts metric definitions. The general idea is to

1. Publish an event (e.g. `authenticator_update`) the subscriber can use to make the metrics updates. This event is published on authenticator configuration update, which we believe takes place exclusively at [update_config](https://github.com/cyberark/conjur/blob/master/app/controllers/authenticate_controller.rb#L65]) in the AuthenticateController.
2. The Prometheus subscriber for these metrics will interpret that event and make appropriate metric updates to the store. In this case the subscriber is responsible for determining the latest authenticators counts by [querying the database](https://github.com/cyberark/conjur/blob/master/app/domain/authentication/installed_authenticators.rb#L23).

  The act of adding the metrics onto the store, combined with the prior work to setup the Prometheus exporter should result in the metric being present in the scrape target endpoint `GET /metrics`.

A/C

- [ ] Authenticators counts metrics are collected
- [ ] Authenticators counts are exposed on the scrape target
- [ ] There are test cases validating this behavior end to end
    + lightweight test: configure authenticators by invoking the authenticate endpoints, and ensure that any changes are reflected in the response of the scrape target endpoint
    + pub/sub plumbing is unit tested so that when policy is loaded (1) an event is dispatched, (2) an event dispatched results in the correct subscriber logic running, (3) the subsciber logic grabs the latest authenticators counts and writes them onto the Prometheus store

### Performance testing of Conjur metrics

Performance testing to ensure that the overhead of adding metrics remains within acceptable bounds. Please consult the [design doc](https://github.com/cyberark/conjur/blob/metrics-solution-design/design/telemetry/metrics_solution_design.md#performance-tests) for details. The intention here is to create a performance baseline for Conjur then compare it with when the feature is complete.

The load applied onto Conjur must be representative of "normal" operation. It must incorporate the typical activities such as authentication, secret retrieval, policy loading, authenticator configuration.

For this task it will be important to collaborate with the Infrastructure team to get data points on what can be defined as "normal" operation. It's with looking at the load used in XA.

A/C

+ A performance baseline has been established prior to adding Conjur metrics
+ A comparison is made between the performance baseline (with Conjur metrics) and with Conjur metrics
+ Negligible performance impact defined by Quality Architect and met by team testing

### Documentation for Conjur metrics

This documentation is for internal consumption. This story is used to hold the multiple documentation tasks

A/C

+ Documentation containing high level overview of telemetry, metric definitions, and how to configure
+ Instructions/guidance for instrumenting additional Conjur metrics reviewed by a member of a different R&D team, as well as a security champion.
+ Documented security guidance for data exposed through telemetry. This should likely include details about why we opted against basic auth for Prometheus, and how it's still possible to add that to the scrape target via load balancer.
+ Documentations + light POC for integrating Conjur Prometheus metrics with AWS CloudWatch, in collaboration with infrastructure team.

### Quick-start for consuming Conjur metrics

Short, simple instructions and scripts/containers for running Prometheus with Conjur OSS.

A/C

+ Tooling of some kind (e.g. Bash script, Docker compose, etc) to launch Conjur OSS and Prometheus, with the latter configured to use the former.
+ Metric and label standards and conventions are documented.
+ README explaining how to use said tooling above.
+ Stretch: tooling also include Grafana hooked up to Prometheus.

## Open Questions
[//]: # "Add any question that is still open. It makes it easier for the reader to have the open questions accumulated here instead of them being acattered along the doc"

<!-- - Enabling/disabling telemetry is intended to not incur any downtime. Environment variables and file config able to accomodate this, while requiring restarts ? -->
<!-- - Does the current implementation ensure that Conjur subprocesses (forks) provide a unified view of the metrics ? -->
<!-- - re: Distributed counts. How are counts aggregated between different nodes ? This should be straightforward when querying from prometheus I think -->
<!-- - re: Maintaining policy resource counts. We need to dive in and understand the feasibility of counting Conjur resources in a granular way that allows each data point to contain the kind label. The count for any given resource type can change only as a result of policy loading. This means that the count must be determined and stored on every policy load. There are some questions around this -->
  <!-- 1. Does the operation of policy loading alone give us the information about the counts ? -->
  <!-- 2. If not (1), then do we need to query the database separately to determine the counts ? If so, how costly is this, how bad can this get, and can it be justified ? -->
  <!-- 3. Is the approach resilient to parallel policy loads ? -->
<!-- - re: Performance testing. For a fully loaded DB, how costly is a count query ? If expensive are there small changes that could make this cheaper, for example keeping a count on the database (perhaps via some stored procedure) ? -->


## Definition of Done

- Solution designed is approved
- Test plan is reviewed
- Acceptance criteria have been met
- Tests are implemented according to test plan
- The behaviour is documented in Conjur Open Source and Enterprise
- All relevant components are released

## Solution Review
[//]: # "Relevant personas can indicate their design approval by approving the pull request"

| **Persona**        | **Name** |
|--------------------|----------|
| Team leader        |     Kumbirai Tanekha     |
| Product owner      |      Alex Kalish      |
| System architect   |          |
| Security architect |          |
| QA architect       |          |
