# Resource Restrictions

##### Note

In this doc, I will cover authenticating hosts with Conjur. Everything about 
authenticating hosts is also relevant to users. For the scope of this document, 
host, user or role are interchangeable.

## Introduction

In several authenticators, such as `authn-k8s`, `authn-azure` and `authn-gcp`,
we require hosts to contain some data which define their identity. This data is
referred to as Resource Restrictions.
The Resource Restrictions give the authenticator another layer of
authentication, where it can authenticate applications using not only their
Conjur identity and permissions (e.g host can `authenticate` with the
authenticator `webservice`) but also their native identity (e.g Azure
resource characteristics)

For example, in the Azure Authenticator the Resource Restrictions include:

- Subscription ID
- Resource Group
- System-Assigned Identity (optional)
- User-Assigned Identity (optional)

A host that will authenticate using the Azure authenticator will be defined
 in its annotations as follows:
 ```yaml
- !host 
  id: test-app 
  annotations: 
    authn-azure/subscription-id: test-subscription 
    authn-azure/resource-group: test-group 
 ```

While in the Azure Authenticator the Resource Restrictions are always stored in
the host annotations, in the Kubernetes Authenticator the Resource Restrictions
can be stored either in the host's ID or in its annotations. 
For example:

 ```yaml
- !host
  id: test-app-service-account
  annotations:
    authn-k8s/namespace: some-namespace
    authn-k8s/service-account: some-service-account

- !host
  id: some-namespace/service_account/some-service-account
 ```

In the example above, both hosts have the same Resource Restrictions. One stores 
it in its annotation and the other in its ID. However, their Conjur identity is
not the same.

## Issue Description

When we add a new authenticator to Conjur, we need to add the mechanism
of validating the host's Resource Restrictions. Currently we have no generic
way to do it and because of that it is less straight-forward to add a new
authenticator. As can be seen in the implementations for the
[Azure Authenticator](/app/domain/authentication/authn_azure/validate_resource_restrictions.rb)
and 
[Kubernetes Authenticator](/app/domain/authentication/authn_k8s/validate_resource_restrictions.rb), 
there is a lot of code duplication with minor changes. 

## Solution

For the sake of simplicity, from here and throughout the document, Resource
Restrictions will be defined only in the host's annotations, and not in the ID. 
In future authenticators we will not develop an option to define it in the ID
and it is available in the K8s Authenticator only for backwards compatibility.

### Defining Resource Restrictions Authentication

The Resource Restrictions authentication is the major flow of actions needed
to validate a request using Resource Restrictions.
It can be split into 3 parts:

 1. Extract the Resource Restrictions from the host
 2. Validate the Resource Restrictions are defined correctly
 3. Validate the Resource Restrictions match the authentication request

Let's break down each part to better understand them.

#### 1. Extract the Resource Restrictions from the host

This step goes to the host in the policy and extracts the Resource Restrictions
from its annotations.

Requirements:

* Extract both **granular restrictions** (starts with `authenticator_name`) and
  **specific restrictions** (starts with `authenticator_name/service_id`).
* If same restriction exist for both **granual** and **specific** restrictions,
  **specific** restrictions should prevail.
* Ignore specific annotations of a different service id
  (starts with `authenticator_name/other_service_id`).
* Return a `resource_restrictions` object of all the restrictions, without their
  prefix.


The `ResourceRestrictions` class is in the form:

```ruby
class ResourceRestrictions
  def initialize(resource_restrictions:)
    @resource_restrictions = resource_restrictions
  end

  def names
    @resource_restrictions.keys
  end

  def each(&block)
    @resource_restrictions.each(&block)
  end
end
```



In this case the general class will be defined as follows:
- input
  - authenticator name
  - authenticator service-id
  - account
  - host name
- output
  - `resource_restrictions` object.
  

So this class signature is:

```ruby
ExtractResourceRestrictions = CommandClass.new(
  dependencies: {
    role_class:     ::Role,
    resource_class: ::Resource,
    logger:         Rails.logger
  },
  inputs:   %i(authenticator_name service_id host_name account)
) do

  def call
    fetch_all_role_annotations
    filter_authenticator_annotations
    convert_to_resource_restrictions
  end

  private
  
  #...

end
```



This is the case also in
[`authn-k8s`](/app/domain/authentication/authn_k8s/resource_restrictions.rb), 
with only one difference as the K8s Authenticator also looks in the host's ID.
To support that, this class can be expanded to extract the constraints from the
host ID, similar to:

```ruby
ExtractK8sResourceRestrictions = CommandClass.new(
  dependencies: {
    role_class:                     ::Role,
    resource_class:                 ::Resource,
    extract_resource_restrictions:  ExtractResourceRestrictions.new,
    logger:                         Rails.logger
  },
  inputs:    %i(authenticator_name service_id host_name account)
) do

  def call
    extract_resource_restrictions_from_annotations
    extract_resource_restrictions_from_host_id if resource_restrictions.empty?
    resource_restrictions
  end

  private
  
  #...

end
```

This class can be used to replace the `ExtractResourceRestrictions` dependency
class for k8s (this is command-class composition to mimic inheritance behavior).

#### 2. Validate the Resource Restrictions are defined correctly

In the Azure Authenticator and in the K8s Authenticator we have constraints on 
how the annotations are defined.

 As can be seen 
[here](/app/domain/authentication/authn_azure/validate_resource_restrictions.rb), 
we have the following validations:

  - Validate only permitted restrictions are defined
    - Here we validate that the `authn-azure` annotations are known. For
      example, the annotation `authn-azure/subscription-id` is valid, whereas
      the annotation `authn-azure/unknown` is invalid. We do that to minimize
      errors from the user, where they will define, for example, the
      annotation `authn-azure/subscription-ir` (note the typo). In this
      case we'd rather fail the authentication and point them to their
      mistake rather than ignore it, and authenticate the request in a weaker
       granularity than what is expected by the user.
  - Validate required restrictions exist
    - For example, in the Azure Authenticator we require hosts to have the
     `subscription-id` and the `resource-group` annotations. In the K8s
      Authenticator we require the `namespace` annotation.
  - Validate mutually exclusive restrictions
    - For example, in the Azure Authenticator we allow hosts to have
     only one of the `user-assigned-identity` and the `system-assigned-identity`
     annotations. In the K8s we allow hosts to have only one of
      the annotations `deployment`, `deployment-config` & `stateful-set`.

Also here we can see some generalization.

These need to be defined for each authenticator.
To simplify that, we can define a simple class for each of these constraints.
The whole constraints will be an array of these constraints, defined once for each authenticator.
Then, to validate the Resource Restrictions, it only needs to loop on these constraints, and invoke
`constraint.validate(resource_restrictions)` on each.

This way, adding or changing the logic is more simple and intuitive, while maintaining readability.

Each of the constraints classes will have the same `validate` signature, and will look similar to:

```ruby
class RequiredConstraint

  def initialize(required:)
    @required = required
  end

  def validate(resource_restrictions:)
    # implement the constraint
  end

end
```

It will be used by each authenticator to define how to validate the configured
restrictions. These are the ones that were defined in the policy for the host,
regardless of the request.

To combine multiple constraints, there will be another `Constraint` class:

```ruby
class MultipleConstraint
  def initialize(*args)
    @constraints = args
  end

  def validate(resource_restrictions:)
    @constraints.each do |constraint|
      constraint.validate(resource_restrictions)
    end
  end
end
```

Example how it will look like for `authn-azure`:

```ruby
REQUIRED = [SUBSCRIPTION_ID, RESOURCE_GROUP]
IDENTITY_EXCLUSIVE = [USER_ASSIGNED_IDENTITY, INFRAPOOL_SYSTEM_ASSIGNED_IDENTITY]
PERMITTED = REQUIRED + IDENTITY_EXCLUSIVE

CONSTRAINTS = MultipleConstraint.new(
        RequiredConstraint.new(required: REQUIRED),
        PermittedConstraint.new(permitted: PERMITTED),
        ExclusiveConstraint.new(exclusive: IDENTITY_EXCLUSIVE)
    )
```

To sum up, this step will call: `constraint.validate(resource_restrictions)`
with the `resource_restrictions` object returned from the previous step.

- output
  - Nothing, relevant error raised if it failed

#### 3. Validate the Resource Restrictions match the authentication request

Once we extracted the Resource Restrictions from the host's annotations, and
verified it is defined correctly, we can validate that the authentication
request is valid by validating the Resource Restrictions. For example, if
the k8s host is permitted to authenticate from namespace `namespace-1`, and
the authentication request was sent from a pod that is in namespace
`namespace-2` we will fail the request.

An AuthenticationRequest object is needed for this step. It is implemented
differently for each authenticator, and exposes a single method:
`retrieve_attribute(restriction_name)`.
This method receives the restrictions name, and retrieve the relevant value
as needed for each authenticator.

All we need to do is iterate over the Resource Restrictions and call it for each
restriction. Then compare the result with the restriction's value:

```ruby
def validate_request_match_resource_restrictions
  resource_restrictions.each do |restriction_name, restriction_value|
    request_value = @request.retrieve_attribute(restriction_name)
    if resource_value != request_value
      raise Errors::Authentication::InvalidResourceRestrictions, restriction_name
    end
  end
end
```

### Summarize

In conclusion, our general AuthenticateWithResourceRestrictions class will need
the following inputs:

  - Authenticator name (e.g 'authn-azure')
  - Authenticator's service-id (e.g 'prod')
  - host name (e.g. 'my-app')
  - account (e.g. 'company')
  - authenticator's constraints object
  - authentication request object

So the class signature will be:

```ruby
AuthenticateWithResourceRestrictions = CommandClass.new(
  dependencies: {
    extract_resource_restrictions:  ExtractResourceRestrictions.new,
    logger:                         Rails.logger
  },
  inputs:   %i(authenticator_name service_id host_name account constraints authentication_request)
) do

  def call
    extract_resource_restrictions
    validate_extracted_resource_restrictions
    validate_request_matches_resource_restrictions
  end

  private
  
  #...

end
```

