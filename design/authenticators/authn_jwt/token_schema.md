# Solution Design - Authn JWT Token Schema

[//]: # "1. Design should be graphical-based and table-based - avoid long text explanations"
[//]: # "2. Design documents should not be updated after implementation"
[//]: # "3. Design decisions should be made before writing this document, and as such this document should not include options / choices"


## Table of Contents
[//]: # "You can use this tool to generate a TOC - https://ecotrust-canada.github.io/markdown-toc/"

- [Solution Design - Authn JWT Token Schema](#solution-design---authn-jwt-token-schema)
  * [Table of Contents](#table-of-contents)
  * [Glossary](#glossary)
  * [Useful Links](#useful-links)
  * [Requirements](#requirements)
  * [Solution](#solution)
    + [User Interface](#user-interface)
      - [Authenticator Policy](#authenticator-policy)
      - [Variable Values Example](#variable-values-example)
  * [Design](#design)
    + [Class Diagrams](#class-diagrams)
    + [Flow Explanation](#flow-explanation)
  * [Backwards Compatibility](#backwards-compatibility)
  * [Affected Components](#affected-components)
  * [Delivery Plan](#delivery-plan)
  * [Delivery Plan](#delivery-plan-1)
  * [Open Questions](#open-questions)
  * [Definition of Done](#definition-of-done)
  * [Solution Review](#solution-review)

## Glossary

[//]: # "Describe terms that will be used throughout the design"
[//]: # "You can use this tool to generate a table - https://www.tablesgenerator.com/markdown_tables#"

| **Term**         | **Description**                                              |
| ---------------- | ------------------------------------------------------------ |
| JWT Claims       | Claims are pieces of information asserted about a subject    |
| Host Annotation  | Defines the checks that we should do on authentication request for host. In JWT authentication its a claim check. |
| Mandatory Claims | JWT-specific claims that a host must validate their existance and value |
| Claims Mapping   | Mapping between claim name and name of host annotation       |

## Useful Links
[//]: # "Add links that may be useful for the reader"

| **Name**   | **Link**                                                     |
| ---------- | ------------------------------------------------------------ |
| JWT Claims | https://auth0.com/docs/tokens/json-web-tokens/json-web-token-claims |

## Requirements
[//]: # "Elaborate on the issue you are writing a solution for"

1. Required fields
   1. In the authenticator policy, the user will have the ability to declare which claims must be in host annotations. As a result, also in the JWT token
   2. When sending an authentication request, the authenticator MUST validate those claims - existence and content 
2. Mapping 
   1. The user should have the ability to map a given "technical" claim name to a more familiar / business one - i.e, in git-lab. Instead of mentioning in the policy "sub" claim, the user will have the ability to mention "job"

## Solution
User will define the token schema variables in the authenticator policy. The variables will be checked in the JWT authentication request.

* The usage of this variables is optional and non mandatory. User can authenticate to JWT in the same way he authenticated in stage 1. Using the feature adds more security checks to the authentication.

### User Interface

#### Authenticator Policy

Two new variables will be added to the authenticator policy:

* mandatory_claims
* claims_mapping

```yaml
    - !policy
    id: conjur/authn-jwt/VendorY
    body:
    - !webservice
    
    - !variable
      id: mandatory_claims
      
    - !variable
      id: claims_mapping
```

#### Variable Values Example

| Name             | Value                   | Description                                      |
| ---------------- | ----------------------- | ------------------------------------------------ |
| mandatory_claims | branch, job, aud        | List of claims as they appear in host annotation |
| claims_mapping   | {ref: branch, sub: job} | Mapping between host annotation to JWT claim     |

* For any claim mapped, we will add the host annotation to the `mandatory_claims` variable and not the JWT claim name.
* The values above are examples and they can be any claims.


## Design
[//]: # "Add any diagrams, charts and explanations about the design aspect of the solution. Elaborate also about the expected user experience for the feature"

The following class diagram, represent the flow of checking the mandatory claims and the claim mapping.

### Class Diagrams


![image-20210711171238701](token-schema-class-diagram.png)

### Flow Explanation

When validate_restrictions is called in JWTVendorConfiguration class the following will happen as a result:

1. The `valitate_restrictions` function will call `CreateConstraintsFromPolicy` that create constraints object checking the hosts annotations.
   1. It will create instance of `NonEmptyConstraint` to check we have at least one host annotation.
   2. It will call `LoadMAndatoryClaims` command class to load the list of mandatory claims for the `mandatory_claims` variable
   3. It will create `RequiredContraint` object from it
2. The `validate_restrictions` functon will call `CreateValidatorFromPolicy` to create validator with the claims mapping loaded
   1. It will call the `LoadClaimsMapping` command class to get dictionary between claim to annotation.
   2. It will create *ValidateRestrictionOneToOne* object and will return it
3. `ValidateResourceRestrictions` will be called with the contraints and the validator from the previous steps. This run will check the claims in the token and annotations. If anything wrong like a missing claim in the host annotation or claim with invalid value and error with be thrown and the authentication request will be denied.

## Backwards Compatibility
[//]: # "How will the design of this solution impact backwards compatibility? Address how you are going to handle backwards compatibility, if necessary"

Token schema is not mandatory therfore the JWT authentication will remain backwards compatible.

## Affected Components

[//]: # "List all components that will be affected by your solution"
[//]: # "[Conjur Open Source/Enterprise, clients, integrations, etc.]"
[//]: # "and elaborate on the impacts. This list should include all"
[//]: # "downstream components that will need to be updated to consume"
[//]: # "new releases as these changes are implemented"

* JWT Authenticator



## Delivery Plan

| Mission                                          | Estimation |
| ------------------------------------------------ | ---------- |
| Support mandatory claims                         | 5 SP       |
| Support claims mapping                           | 5 SP       |
| Add status checks for token schema configuration | 2 SP       |
| Add Cucumber tests for token schema              | 5 SP       |

## Open Questions
[//]: # "Add any question that is still open. It makes it easier for the reader to have the open questions accumulated here instead of them being acattered along the doc"

* How the `claims_mapping` should look like
  * Option 1: A dictionary
    `{ref: branch, sub: job}`
  * Option 2: Just the paris
    `ref:branch, sub:job`
* What is the expected behaviour if we recive on of this standard claims in the `mandatory_claims` or `claims_mapping`
  * iss
  * iat
  * exp
  * nbf

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
| Team leader        |          |
| Product owner      |          |
| System architect   |          |
| Security architect |          |
| QA architect       |          |
