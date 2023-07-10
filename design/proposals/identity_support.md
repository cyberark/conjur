# Solution Design - Identity Support
[//]: # "Change the title above from 'Template' to your design's title"

[//]: # "General notes:"
[//]: # "1. Design should be graphical-based and table-based - avoid long text explanations"
[//]: # "2. Design documents should not be updated after implementation"
[//]: # "3. Design decisions should be made before writing this document, and as such this document should not include options / choices"

## Table of Contents
[//]: # "You can use this tool to generate a TOC - https://ecotrust-canada.github.io/markdown-toc/"

- [Solution Design - Identity Support](#solution-design---identity-support)
  - [Table of Contents](#table-of-contents)
  - [Background](#background)
  - [Issue Description](#issue-description)
  - [Solution](#solution)
    - [API Differences: Okta vs Identity](#api-differences--okta-vs-identity)
      - [Important Notes](#important-notes)
    - [User Interface](#user-interface)
  - [Design](#design)
  - [Backwards Compatibility](#backwards-compatibility)
  - [Affected Components](#affected-components)
  - [Work in Parallel](#work-in-parallel)
  - [Test Plan](#test-plan)
    - [Test Assumptions](#test-assumptions)
    - [Out of Scope](#out-of-scope)
    - [Prerequisites](#prerequisites)
    - [Test Cases (Including Performance)](#test-cases--including-performance-)
      - [Functional Tests](#functional-tests)
  - [Documentation](#documentation)
  - [Security](#security)
  - [Infrastructure](#infrastructure)
  - [Audit](#audit)
  - [Open Questions](#open-questions)
  - [Definition of Done](#definition-of-done)
  - [Solution Review](#solution-review)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

## Background
[//]: # "Give relevant background for the designed feature. What is the motivation for this solution?"

Given the recent upgrades to the V2 OIDC Authenticator, and that the only currently
supported OIDC provider is Okta, we should upgrade the V2 OIDC Authenticator to
support CyberArk Identity.

See existing [documentation](https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/OIDC/OIDC-for-UI-and-CLI.htm?tocpath=Integrations%7COpenID%20Connect%20(OIDC)%20Authenticator%7C_____2)
and [implementation](https://github.com/cyberark/conjur/tree/master/app/domain/authentication/authn_oidc/pkce_support_feature)
for AuthnOIDC V2.

## Issue Description
[//]: # "Elaborate on the issue you are writing a solution for"

Conjur's AuthnOIDC V2 implementation is intended to be, for the most part, provider
agnostic. This is in large part because the endpoints of the OIDC API that Conjur
interacts with are well-defined across the various OIDC specifications. This solution
will mostly cover:
1. API differences between Okta and Identity
2. Required testing updates across concerned projects
3. Required documentation updates

## Solution
[//]: # "Elaborate on the solution you are suggesting in this page. Address the functional requirements and the non functional requirements that this solution is addressing. If there are a few options considered for the solution, mention them and explain why the actual solution was chosen over them. Add an execution plan when relevant. It doesn't have to be a full breakdown of the feature, but just a recommendation to how the solution should be approached."

### API Differences: Okta vs Identity

In theory, AuthnOIDC V2 should support any OIDC provider that adheres to the
OIDC specifications. The following section will examine the Okta and Identity
OIDC APIs, and try to determine whether support for one implies support for the
other.

The following table displays the differences between the API endpoint paths
required for Conjur's AuthnOIDC V2 flow.

| Endpoint | Okta | Identity |
|----------|------|----------|
| Metadata | `/.well-known/openid-configuration` | `/${app_id}/.well-known/openid-configuration` |
| Authz    | Parsed from provider metadata | Parsed from provider metadata |
| Token    | Parsed from provider metadata | Parsed from provider metadata |

Given that the Authz and Token endpoints are both parsed from the provider's
metadata endpoint, differences in path structure will not matter. As long as the
`${app_id}` is included in the path of the provider URI set up during Authenticator
configuration, it should propagate to the rest of the API paths.

The following table displays the differences between the API endpoint parameters
required for Conjur's AuthnOIDC V2 flow.

| Endpoint | Okta: Required | Okta: Optional | Identity: Required | Identity: Optional |
|----------|----------------|----------------|--------------------|--------------------|
| Metadata | None | None | None | None |
| Authz    | <ul><li>`client_id`<li>`redirect_uri`<li>`response_type`<li>`scope`<li>`state`</ul> | <ul><li>`code_challenge`<li>`code_challenge_method`<li>`nonce`</ul> | <ul><li>`client_id`<li>`redirect_uri`<li>`response_type`<li>`scope`<li>`state`<li>`app_id` (path, given)</ul> | <ul><li>`code_challenge`<li>`code_challenge_method`<li>`nonce`</ul> |
| Token    | <ul><li>`grant_type`<li>`code`<li>`code_verifier`<li>`redirect_uri`</ul> | None | <ul><li>`grant_type`<li>`code`<li>`code_verifier`<li>`redirect_uri`<li>`client_id`<li>`app_id` (path, given)</ul> | None |

#### Important Notes

1. Identity requires the `client_id` parameter on token requests [[1](https://identity-developer.cyberark.com/reference/post_oauth2-token-app-id)].

   In the current AuthnOIDC implementation, the `client_id` and `client_secret`
   credential pair are sent to the OIDC provider (currently Okta) in an
   Authorization header [[2](https://github.com/cyberark/conjur/blob/master/app/domain/authentication/authn_oidc/pkce_support_feature/client.rb#L42)].

   From Identity's documentation, it is not clear whether an Authorization header
   containing the `client_id` and `client_secret` parameters will be accepted as
   it is by Okta. If the Authz Header is accepted, then no changes are required.
   If the Authz Header is not accepted, then we could configure the OIDC client
   to send the required parameters as part of the request body, which is also
   accepted by Okta.

   Update: After setting up Conjur UI with an AuthnOIDC V2 instance backed by
   Identity, this concern does not require any changes to Conjur's OIDC client.
   The client successfully authenticates with Identity as currently implemented.

### User Interface
[//]: # "Describe user interface (including command structure, inputs/outputs, etc where relevant)"

The user interface for an AuthnOIDC V2 instance representing Identity will be the
same as one representing Okta.

## Design
[//]: # "Add any diagrams, charts and explanations about the design aspect of the solution. Elaborate also about the expected user experience for the feature"

Depending on the answers to the questions listed in the [API Differences](#api-differences-okta-vs-identity)
section, there may be no need to code changes beyond those made to testing.

## Backwards Compatibility
[//]: # "How will the design of this solution impact backwards compatibility? Address how you are going to handle backwards compatibility, if necessary"

Depending on the answers to the questions listed in the [API Differences](#api-differences-okta-vs-identity)
section, there may be no need to code changes beyond testing, and will be backwards
compatible.

## Affected Components
[//]: # "List all components that will be affected by your solution"
[//]: # "[Conjur Open Source/Enterprise, clients, integrations, etc.]"
[//]: # "and elaborate on the impacts. This list should include all"
[//]: # "downstream components that will need to be updated to consume"
[//]: # "new releases as these changes are implemented"

- [Conjur Open Source](https://github.com/cyberark/conjur)
- [Conjur UI](https://github.com/conjurinc/conjur-ui)
- [Go-based Conjur CLI](https://github.com/cyberark/conjur-cli-go)

## Work in Parallel
[//]: # "How can we work in parallel for this task? How this can be done effectively without hindering the work of others who are working on different areas of the task."
[//]: # "For example, can we introduce minimal automation to run basic sanity tests to protect the work of others?"

Given that the bulk of the work required to validate support for Identity will
be as dev environment and testing updates, the following work can be done in parallel:

1. Enable Identity development across required projects by including Identity in
   existing development and CI environments.
   - Conjur
   - Conjur UI
   - Conjur CLI Go
2. Add Identity to testing strategy across required projects
   - Conjur. See [test cases summary](#functional-tests).
   - Conjur UI. See [test cases summary](#functional-tests).
   - Conjur CLI Go. See [test cases summary](#functional-tests).

## Test Plan

### Test Assumptions

- The current AuthnOIDC V2 test matrix that validates support for Okta, if
  repurposed to target Identity, would also validate support for Identity.

### Out of Scope

- Validating support for a general OIDC provider.

### Prerequisites
[//]: # "List any expected infrastructure requirements here"

- Identity instance available for testing in CI
- Identity instance available for development environment

### Test Cases (Including Performance)

#### Functional Tests

[//]: # "Fill in the table below to depict the tests that should run to validate your solution"
[//]: # "You can use this tool to generate a table - https://www.tablesgenerator.com/markdown_tables#"

| **Component** | **Title** | **Given** | **When** | **Then** | **Comment** |
|---------------|-----------|-----------|----------|----------|-------------|
| conjur        | Happy Path Integration Test | Given an AuthnOIDC V2 instance is properly configured to authenticate with an Identity instance | When a user properly authenticates with AuthnOIDC V2 through Conjur's API | Then the user is authenticated and given a Conjur access token | See [Conjur's Happy Path Integration Test for Okta](https://github.com/cyberark/conjur/blob/master/cucumber/authenticators_oidc/features/authn_oidc_okta.feature) |
|               | Multi-Authenticator, Multi-Provider Environment | Given a Conjur server has been configured with more than one AuthnOIDC V2 instance, and given that those instances each point to a different OIDC provider (e.g. Okta and Identity) | When a user authenticates with one authenticator | Then the other authenticators are unaffected, and can be used as expected | |
|               | OIDC Client Unit Tests | | | | There are a number of [RSpec unit tests](https://github.com/cyberark/conjur/blob/master/spec/app/domain/authentication/authn-oidc/pkce_support_feature/client_spec.rb) that validate Conjur's [OIDC client wrapper](https://github.com/cyberark/conjur/blob/master/app/domain/authentication/authn_oidc/pkce_support_feature/client.rb). These depend on VCR to playback [authentic Okta API calls](https://github.com/cyberark/conjur/tree/master/spec/fixtures/vcr_cassettes/authenticators/authn-oidc/pkce_support_feature) - these should be supplemented with authentic Identity API calls, so each unit test case can be run against each to validate compatibility. See [this issue in rspec/rspec-core](https://github.com/rspec/rspec-core/issues/2663#issuecomment-533634878) for an example. |
| conjur-cli-go | Happy Path Integration Test | Given an AuthnOIDC V2 instance is properly configured to authenticate with an Identity instance | When a user properly authenticates with AuthnOIDC V2 through the Go CLI | Then the user can use the CLI to perform authorized actions, like policy load and secret retrieval. | See [Conjur Go CLI's Happy Path Integration Test for Okta](https://github.com/cyberark/conjur-cli-go/blob/master/cmd/integration/oidc_integration_test.go#L146) |
|               | Bad Credentials Integration Test | Given an AuthnOIDC V2 instance is properly configured to authenticate with an Identity instance | When a user attempts to authenticate with Identity with invalid credentials | Authentication fails, and the CLI eventually times-out the authentication command | |
| conjur-ui     | Happy Path Integration Test | Given an AuthnOIDC V2 instance is properly configured to authenticate with an Identity instance | When a user properly authenticates with AuthnOIDC V2 through the UI | Then the user is logged in to the UI | See [Conjur UI's Happy Path Integration Test for Okta](https://github.com/conjurinc/conjur-ui/blob/caf72e0cd8acb3dd3d9c8ab6556a42f4aec7d7fa/features/okta.feature) |
|               | Bad Credentials Integration Test | Given an AuthnOIDC V2 instance is properly configured to authenticate with an Identity instance | When a user attempts to authenticate with Identity with invalid credentials | Authentication fails, and the user is not redirected to Conjur UI | |

## Documentation
[//]: # "Add notes on what should be documented in this solution. Elaborate on where this should be documented, including GitHub READMEs and/or official documentation."

- [OpenID Connect (OIDC) Authenticator](https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/OIDC/OIDC.htm?tocpath=Integrations%7COpenID%20Connect%20(OIDC)%20Authenticator%7C_____0)

  Limitations section lists Okta as the only available provider. This list needs to be updated.

- [OIDC Authenticator for Conjur UI and Conjur CLI](https://docs.cyberark.com/Product-Doc/OnlineHelp/AAM-DAP/Latest/en/Content/OIDC/OIDC-for-UI-and-CLI.htm#OIDC%C2%A0Aut2) 

  There are a lot of points in the documentation where we describe a service or
  configuration based on Okta, but we could change this to Identity to be internally consistent.

An important detail: Identity has a `client_id`, which is defined in the OIDC
specification, and an `app_id`. These are separate IDs, with `app_id` being a path
parameter and `client_id` being a query or request body parameter. The `app_id`
value must be included in the AuthnOIDC V2 config variable `provider-id`. When
included, the `app_id` value will propagate to the Authz and Token endpoints
through provider metadata retrieval.

## Security
[//]: # "Are there any security issues with your solution? Even if you mentioned them somewhere in the doc it may be convenient for the security architect review to have them centralized here"

Given the limited scope of this effort, and given the rigorous consideration of
security issues before and during the initial implementation of AuthnOIDC V2, I
have not encountered any new security concerns.

## Infrastructure

[//]: # "Does your solution require assistence from the Infrastructure team? Take a moment to elaborate in this section on the types of items that you require and create issues in the ops project: https://github.com/conjurinc/ops/issues. It is best to make these requests as soon as possible as it may require some time to deliver."

This solution depends on the Infrastructure team providing a CyberArk Identity
instance for development and testing. This is in progress.

## Audit

[//]: # "Does this solution require adding audit logs? Does it affect existing audit logs?"

| **Name (ID)** | **Description** | **Issued On** |
|---------------|-----------------|---------------|
|               |                 |               |

## Open Questions
[//]: # "Add any question that is still open. It makes it easier for the reader to have the open questions accumulated here instead of them being acattered along the doc"

See **API Differences: Okta vs Identity** subsection [**Important Notes**](#important-notes).

## Definition of Done

- Solution designed is approved
- Test plan is reviewed
- Acceptance criteria have been met
- Tests are implemented according to test plan 
- The behaviour is documented in Conjur Open Source and Enterprise
- Documentation has been validated by a manual UX walkthrough
- All relevant components are released

## Solution Review
[//]: # "Relevant personas can indicate their design approval by approving the pull request"

| **Persona**        | **Name**                        | **Sign-off** |
|--------------------|---------------------------------|--------------|
| Team leader        | John Tuttle (@jtuttle)          |    |
| Product owner      | Nitesh Taneja (@niteshtaneja)   | ✅ |
| System architect   | Jason Vanderhoof (@jvanderhoof) | ✅ |
| Security architect | Andy Tinkham (@andytinkham)     | ✅ |
| QA architect       | Adam Ouamani (@adamoumani)      | ✅ |