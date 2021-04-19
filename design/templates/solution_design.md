# Solution Design - Template
[//]: # "Change the title above from 'Template' to your design's title"

[//]: # "General notes:"
[//]: # "1. Design should be graphical-based and table-based - avoid long text explanations"
[//]: # "2. Design documents should not be updated after implementation"
[//]: # "3. Design decisions should be made before writing this document, and as such this document should not include options / choices"


## Table of Contents
[//]: # "You can use this tool to generate a TOC - https://ecotrust-canada.github.io/markdown-toc/"

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
| Feature Doc |          |
| Issue       |          |

## Background
[//]: # "Give relevant background for the designed feature. What is the motivation for this solution?"

## Issue Description
[//]: # "Elaborate on the issue you are writing a solution for"

## Solution
[//]: # "Elaborate on the solution you are suggesting in this page. Address the functional requirements and the non functional requirements that this solution is addressing. If there are a few options considered for the solution, mention them and explain why the actual solution was chosen over them. Add an execution plan when relevant. It doesn't have to be a full breakdown of the feature, but just a recommendation to how the solution should be approached."

### User Interface
[//]: # "Describe user interface (including command structure, inputs/outputs, etc where relevant)"

Command:

Input parameters:

| **Name** | **Description** | **Type** | **Default** | **Required?** |
|----------|-----------------|----------|-------------|---------------|
|          |                 |          |             |               |

Output parameters:

| **Name** | **Description** | **Type** |
|----------|-----------------|----------|
|          |                 |          |


## Design
[//]: # "Add any diagrams, charts and explanations about the design aspect of the solution. Elaborate also about the expected user experience for the feature"

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

## Affected Components
[//]: # "List all components that will be affected by your solution [Conjur OSS, Conjur Enterprise, clients, integrations, etc.] and elaborate on the impacts"
[//]: # "This list should include all downstream components that will need to be updated to consume new releases as these changes are implemented"

## Test Plan

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

| **Scenario** | **Spec** | **Environment(s)** | **Comments** |
|--------------|----------|--------------------|--------------|
|              |          |                    |              |

## Logs
[//]: # "If the logs are listed in the feature doc, add a link to that section. If not, list them here."
[//]: # "You can use this tool to generate a table - https://www.tablesgenerator.com/markdown_tables#"

| **Scenario** | **Log message** |
|--------------|-----------------|
|              |                 |
|              |                 |

## Documentation
[//]: # "Add notes on what should be documented in this solution. Elaborate on where this should be documented, including GitHub READMEs and/or official documentation."

## Security
[//]: # "Are there any security issues with your solution? Even if you mentioned them somewhere in the doc it may be convenient for the security architect review to have them centralized here"

| **Security Issue** | **Description** | **Resolution** |
|--------------------|-----------------|----------------|
|                    |                 |                |

## Infrastructure

[//]: # "Does your solution require assistence from the Infrastructure team? Take a moment to elaborate in this section on the types of items that you require and create issues in the ops project: https://github.com/conjurinc/ops/issues. It is best to make these requests as soon as possible as it may require some time to deliver."

## Audit

[//]: # "Does this solution require adding audit logs? Does it affect existing audit logs?"

| **Name (ID)** | **Description** | **Issued On** |
|---------------|-----------------|---------------|
|               |                 |               |

## Open Questions
[//]: # "Add any question that is still open. It makes it easier for the reader to have the open questions accumulated here instead of them being acattered along the doc"

## Definition of Done

- Solution designed is approved 
- Test plan is reviewed
- Acceptance criteria have been met
- Tests are implemented according to test plan 
- The behaviour is documented in Conjur OSS and Enterprise
- All relevant components are released

## Solution Review
[//]: # "Relevant personas can indicate their design approval by approving the pull request"

| **Persona**        | **Name** |
|--------------------|----------|
| Team leader        |          |
| Product owner      |          |
| System architect   |          |
| Security architect |          |
| QA architect       |          |
