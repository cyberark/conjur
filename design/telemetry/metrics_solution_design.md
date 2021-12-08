# Solution Design - Conjur Metrics Telemetry

[//]: # "General notes:"
[//]: # "1. Design should be graphical-based and table-based - avoid long text explanations"
[//]: # "2. Design documents should not be updated after implementation"
[//]: # "3. Design decisions should be made before writing this document, and as such this document should not include options / choices"


## Table of Contents
[//]: # "You can use this tool to generate a TOC - https://ecotrust-canada.github.io/markdown-toc/"

- [Solution Design - Conjur Metrics Telemetry](#solution-design---conjur-metrics-telemetry)
  * [Table of Contents](#table-of-contents)
  * [Glossary](#glossary)
  * [Useful Links](#useful-links)
  * [Background](#background)
    + [Conjur Metrics Telemetry](#conjur-metrics-telemetry)
  * [Issue Description](#issue-description)
  * [Solution](#solution)
    + [Solution overview](#solution-overview)
    + [Rationale](#rationale)
    + [Instrumented Metrics](#instrumented-metrics)
      - [Conventions](#conventions)
      - [Metrics](#metrics)
        * [Conjur HTTP Requests](#conjur-http-requests)
        * [Conjur Resources](#conjur-resources)
    + [User Interface](#user-interface)
  * [Design](#design)
    + [Implementation Details](#implementation-details)
    + [Flow Diagrams](#flow-diagrams)
    + [Class / Component Diagrams](#class---component-diagrams)
      - [Class / Details](#class---details)
    + [Sequence Diagrams](#sequence-diagrams)
    + [External Interfaces](#external-interfaces)
  * [Performance](#performance)
  * [Backwards Compatibility](#backwards-compatibility)
  * [Affected Components](#affected-components)
  * [Work in Parallel](#work-in-parallel)
  * [Test Plan](#test-plan)
    + [Test Environments](#test-environments)
    + [Test Assumptions](#test-assumptions)
    + [Out of Scope](#out-of-scope)
    + [Prerequisites](#prerequisites)
    + [Test Cases (Including Performance)](#test-cases--including-performance-)
      - [Functional Tests](#functional-tests)
      - [Security Tests](#security-tests)
      - [Error Handling / Recovery / Supportability tests](#error-handling---recovery---supportability-tests)
      - [Performance Tests](#performance-tests)
  * [Logs](#logs)
  * [Documentation](#documentation)
  * [Security](#security)
  * [Infrastructure](#infrastructure)
  * [Audit](#audit)
  * [Open Questions](#open-questions)
  * [Definition of Done](#definition-of-done)
  * [Solution Review](#solution-review)

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
  - API call response codes and durations. API calls identified by their Open API Spec `operationId`.
  - Current count of policy resources (e.g. hosts, secrets)
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
    gauge in seconds.
- Labels
  - `code`: HTTP status code, such as `200` or `301`.
  - `operation`: The Open API Spec `operationId` for each requested endpoint.

*Note*: Some may noticed the absence of `path` in the labels above. This is an
intentional design choice, given our extensive use of path parameters with
sensitive values.

  
##### Conjur Resources

Resources managed by Conjur (i.e. roles, resources, hosts, etc).

- Metrics
  - `conjur_server_policy_*`: Total count of particular types of resources stored by Conjur, such as hosts, variables and users.
- Labels
  - `kind`: Resource type.
  - 

**TODO:** We need to dive in and understand the feasibility of counting Conjur resources in a granular way that allows each data point to contain the kind label. The count for any given resource type can change only as a result of policy loading. This means that the count must be determined and stored on every policy load. There are some questions around this
  1. Does the operation of policy loading alone give us the information about the counts ?
  2. If not (1), then do we need to query the database separately to determine the counts ? If so, how costly is this, how bad can this get, and can it be justified ?
  3. Is the approach resilient to parallel policy loads ?
  
  
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

### Gathering metrics and exposing the `/metrics` endpoint

[Prometheus client ruby](https://github.com/prometheus/client_ruby) provides a nice and standard API for collecting and exposing metrics (`Prometheus::Client::Formats::Text.marshal(registry)`) in the desired format. It also provide examples of Rack middleware for tracing all HTTP requests ([collector](https://github.com/prometheus/client_ruby/blob/master/lib/prometheus/middleware/collector.rb)) and exposing a metrics HTTP endpoint to be scraped by a Prometheus server ([exporter](https://github.com/prometheus/client_ruby/blob/master/lib/prometheus/middleware/exporter.rb))
 
#### Gathering metrics

The goal here is to have a flexible and extensible mechanism for gathering metrics. At present there are 2 types of metrics that we are currently interested in: HTTP requests and Conjur resource counts. The points where the information for these metrics becomes available can be different, for example HTTP requests can be instrumented through Rack middleware while resource counts must be dynamically determine after policy is run. To avoid coupling the implementation with the points where the metric information is available we must make use of patterns like
 1. Dependency injection, so that the Prometheus registry used for recording metrics can be passed in where it is needed. This also allows for easier testing
 2. Pub/sub, so that the places where the information becomes available for metrics contains no implementation-specific code and we instead publish the metric information and delegate the collection to some subscriber that contains the implementation-specific code.
    
    NOTE: The hackathon project makes use of `ActiveSupport::Notifications`, which provides a pub/sub pattern that is native to Rails. **TODO:** confirm if this is [blocking](https://stackoverflow.com/questions/16651321/activesupportnotifications-should-be-async) or is async. 
 
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
|             |                 |                      |

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
  
**TODO:** Elaborate on the test plan. Some thoughts on testing metrics telemetry
  1. The functionality of metrics telemetry can be unit-tested. In unit tests we can compare, for any given action, the value registered by prometheus against the base truth. This validates how we are measuring.


### Test Environments
[//]: # "Including build number, platforms etc. Considering the OS and version of PAS (PVWA, CPM), Conjur, Synchronizer etc."

| **Feature** | **OS** | **Version Number** |
|-------------|--------|--------------------|
|             |        |                    |

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
|           |           |          |          |             |
|           |           |          |          |             |

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

**TODO:** Elaborate on the performance test. Some thoughts
1. Performance testing can be carried out by introducing a particular load to Conjur with and without telemetry, and comparing the statistics.

| **Scenario** | **Spec** | **Environment(s)** | **Comments** |
|--------------|----------|--------------------|--------------|
|              |          |                    |              |

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
2. Documentation for configuring Conjur metrics telemetry
3. Documentation for integrating Conjur metrics telemetry [with AWS CloudWatch](https://aws.amazon.com/blogs/containers/amazon-cloudwatch-prometheus-metrics-ga/)
4. Source code documentation for adding new metrics (and extending functionality)
5. Short, simple instructions and scripts for running Prometheus with Conjur OSS
Update the Secrets Provider application container configuration documentation.
Add new documentation to describe the push-to-file annotation configuration
Add documentation for the process to upgrade from the Secrets Provider legacy (environment variable based) configuration to the annotation-based configuration.

## Security
[//]: # "Are there any security issues with your solution? Even if you mentioned them somewhere in the doc it may be convenient for the security architect review to have them centralized here"

| **Security Issue** | **Description** | **Resolution** |
|--------------------|-----------------|----------------|
|                    |                 |                |

## Infrastructure

[//]: # "Does your solution require assistence from the Infrastructure team? Take a moment to elaborate in this section on the types of items that you require and create issues in the ops project: https://github.com/conjurinc/ops/issues. It is best to make these requests as soon as possible as it may require some time to deliver."

## Audit

[//]: # "Does this solution require adding audit logs? Does it affect existing audit logs?"

<!-- | **Name (ID)** | **Description** | **Issued On** |
|---------------|-----------------|---------------|
|               |                 |               |
 -->

N/A

## Open Questions
[//]: # "Add any question that is still open. It makes it easier for the reader to have the open questions accumulated here instead of them being acattered along the doc"

- How to authenticate and authorize the metrics endpoint?
- Enabling/disabling telemetry is intended to not incur any downtime. Are environment variables and file config able to accomodate this, while requiring restarts ?
- Does the current implementation ensure that Conjur subprocesses (forks) provide a unified view of the metrics ?
- How do we effeciently determine resource count (granular to the resource type)?
- Distributed counts, how are counts aggregated between different nodes ? This should be straightforward when querying from prometheus I think
 
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
| Product owner      |    	Alex Kalish      |
| System architect   |          |
| Security architect |          |
| QA architect       |          |
