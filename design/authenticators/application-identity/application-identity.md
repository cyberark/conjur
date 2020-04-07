# Application Identity

##### Note

In this doc, I will cover authenticating hosts with Conjur. Everything about 
authenticating hosts is also relevant to users. For the scope of this document, 
host, user or role are interchangeable.
  
## Introduction

In several authenticators, such as `authn-k8s` & `authn-azure`, we require hosts 
to contain some data which define their identity. This data is referred to as Application Identity. 
The Application Identity gives the authenticator another layer of
authentication, where it can authenticate applications using not only their
Conjur identity and permissions (e.g host can `authenticate` with the
authenticator `webservice`) but also their native identity (e.g Azure
resource characteristics)
 
For example, in the Azure Authenticator the Application Identity includes:
- Subscription ID
- Resource Group
- System-Assigned Identity (optional)
- User-Assigned Identity (optional)
 
A host that will authenticate using the Azure authenticator will be defined
 in its annotations as follows:
 ```
- !host 
  id: test-app 
  annotations: 
    authn-azure/subscription-id: test-subscription 
    authn-azure/resource-group: test-group 
``` 

While in the Azure Authenticator the Application Identity is always stored in the host annotations,
in the Kubernetes Authenticator the Application Identity can be stored either
in the host's ID or in its annotations. 
For example:
 ```
- !host
  id: test-app-service-account
  annotations:
    authn-k8s/namespace: some-namespace
    authn-k8s/service-account: some-service-account

- !host
  id: some-namespace/service_account/some-service-account
```

In the example above, both hosts have the same Application Identity. One stores 
it in its annotation and the other in its ID. However, their Conjur identity is not
the same.

## Issue Description

When we add a new authenticator to Conjur, we need to add the mechanism
of validating the host's Application Identity. Currently we have no generic
way to do it and because of that it is less straight-forward to add a new
authenticator. An example of what a generic implementation is can be seen in
the [Authenticator Status Check](../authenticators-status). As you can see
in the [Implementing Authenticator Status API](../authenticators-status/authn-status-new-implem.md) 
doc, it is very simple to add a new Status Check to an Authenticator. This happens because the flow
starts with general checks that are relevant to all authenticators, and all
that needs to be done in order to add a new Status Check is to implement a
method named `status` in the relevant `Authenticator` class, and create a
Command Class that will perform the actual validations. 
 
However, when validating the Application Identity we currently have no
generic mechanism, as can be seen in the implementations for the [Azure
Authenticator](/app/domain/authentication/authn_azure/validate_application_identity.rb) and 
[Kubernetes Authenticator](/app/domain/authentication/authn_k8s/validate_application_identity.rb), 
where a lot of code is duplicated with minor changes. 

## Solution

Before we can find the solution, we need to understand how Application
Identities are related across authenticators, and how they are different.
 
For the sake of simplicity, from here and throughout the document, Application 
Identities will be defined only in the host's annotations, and not in the ID. 
In future authenticators we will not develop an option to define it in the ID and it
is available in the K8s Authenticator only for backwards compatibility.

### Defining Application Identity Validation

The Application Identity validation can be roughly split into 3 parts:
 - Extract the Application Identity from the host
 - Validate the Application Identity is defined correctly
 - Validate the Application Identity matches the authentication request

Let's break down each part to better understand them.

#### Extract the Application Identity from the host

Let's look into the Azure Authenticator's Application Identity class:
```
class ApplicationIdentity

    def initialize(role_annotations:, service_id:, logger:)
        @role_annotations = role_annotations
        @service_id       = service_id
        @logger           = logger
    end
    
    def constraints
        @constraints ||= {
          subscription_id:          constraint_value("subscription-id"),
          resource_group:           constraint_value("resource-group"),
          user_assigned_identity:   constraint_value("user-assigned-identity"),
          system_assigned_identity: constraint_value("system-assigned-identity")
        }.compact
    end
    
    private
    
    # check the `service-id` specific constraint first to be more granular
    def constraint_value constraint_name
        annotation_value("authn-azure/#{@service_id}/#{constraint_name}") ||
          annotation_value("authn-azure/#{constraint_name}")
    end
    
    def annotation_value name
        annotation = @role_annotations.find { |a| a.values[:name] == name }
        
        # return the value of the annotation if it exists, nil otherwise
        if annotation
          @logger.debug(LogMessages::Authentication::RetrievedAnnotationValue.new(name))
          annotation[:value]
    end
end
```

The class gets the host's annotations and the authenticator's service-id, 
and then builds a `constraints` hash from the annotations. 

This is the case also in [`authn-k8s`](/app/domain/authentication/authn_k8s/application_identity.rb), 
with only one difference as the K8s Authenticator also looks in the host's ID. 

Putting that aside we can see that the behavior is exactly the same. 
In this case the general class will be defined as follows:
- input
  - authenticator name
  - authenticator service-id
  - annotations
  - List of relevant annotations (e.g `[subscription-id, resource-group
  , system-assigned-identity, user-assigned-identity]
  ` for `authn
  -azure`)
- output
  - `constraints` hash.
   
#### Validate the Application Identity is defined correctly

In the Azure Authenticator and in the K8s Authenticator we have requirements on 
how the annotations are defined. As can be seen 
[here](/app/domain/authentication/authn_azure/validate_application_identity.rb), 
we have the following validations:
  - Validate annotations are permitted
    - Here we validate that the `authn-azure` annotations are known. For
      example, the annotation `authn-azure/subscription-id` is valid, whereas
      the annotation `authn-azure/blah` is invalid. We do that to minimize
      errors from the user, where they will define, for example, the
      annotation `authn-azure/subscription-ir` (note the typo). In this
      case we'd rather fail the authentication and point them to their
      mistake rather than ignore it, and authenticate the request in a weaker
       granularity than what is expected by the user.
  - Validate required constraints exist
    - For example, in the Azure Authenticator we require hosts to have the
     `subscription-id` and the `resource-group` annotations. In the K8s
      Authenticator we require the `namespace` annotation.
  - Validate constraint combinations
    - For example, in the Azure Authenticator we do not allow hosts to have
     both the `user-assigned-identity` and the `system-assigned-identity`
     annotations. In the K8s we do not allow hosts to have any combination of
      the annotations `deployment`, `deployment-config` & `stateful-set`.
      
Also here we can see some generalization. 
In this case the general class will be defined as follows:
- input
  - The following lists of annotation names
    - permitted
    - required
    - non-permitted combinations
  - The `constraints` hash built in the previous step
- output
  - Nothing if validation succeeded, relevant error if it failed

#### Validate the Application Identity matches the authentication request

Once we extracted the Application Identity from the host's annotations, and
verified it is defined correctly, we can validate that the authentication
request is valid by validating the Application Identity. For example, if
the k8s host is permitted to authenticate from namespace `namespace-1`, and
the authentication request was sent from a pod that is in namespace
`namespace-2` we will fail the request.

In a way, we can define this step as comparing 2 objects of Application
Identity - one that was extracted from the host and one that was extracted
from the authentication request. In the example above we will have the
following Application Identity objects:
 - Host Application Identity
   - constraints
     - namespace: `namespace-1`
 - Authentication request Application Identity
   - constraints
     - namespace: `namespace-2`
     
All we need to do is iterate over the Host Application Identity `constraints` hash 
and verify that all of its fields have the same values as the 
corresponding `constraints` hash fields in the Authentication request Application Identity object.

In this case the general class will be defined as follows:
- input
  - Host Application Identity object
  - Authentication request Application Identity object
- output
  - Nothing if validation succeeded, InvalidApplicationIdentity error if it
   failed
   
### Implementation

In conclusion, our general ValidateApplication class will need the following
inputs:
  - Authenticator name (e.g 'authn-azure')
  - Authenticator's service-id (e.g 'prod')
  - host's annotations
  - Different lists of annotation names
    - permitted
    - required
    - non-permitted combinations
  - Authentication request Application Identity object
  
It will perform the following steps:
  1. Build the Host Application Identity object using the:
     - authenticator name
     - authenticator service-id
     - host's annotations
     - list of permitted annotations
  2. Verify the Host Application Identity is configured correctly using the:
     - Host Application Identity object built in the previous step
     - list of required constraints
     - list of non-permitted constraints combinations
  3. Verify the Host Application Identity matches the authentication request
   using the:
     - Host Application Identity object built in the first step
     - Authentication request Application Identity object given in the input
      to this class
      
Let's see how the classes will look like, at a high level. After we go over all the
classes, we'll see a usage example for the Azure Authenticator.

#### Application Identity class

We will have 2 different Application Identity classes. Although their
interface is the same, they are not entirely identical. 

At first, the `constraints` method will return a simple key-value hash. We
should challenge that and find a better way to do it in Ruby.

##### Host Application Identity

```
class HostApplicationIdentity

  def initialize(authenticator_name:, service_id:, role_annotations:, permitted_constraints:)
    @authenticator_name = authenticator_name
    @service_id       = service_id
    @role_annotations = role_annotations
    @permitted_constraints = permitted_constraints
  end

  def constraints
    @constraints ||= @permitted_constraints.each_with_object({}) do |annotation_name, constraints|
      constraints[annotation_name] = constraint_value(annotation_name)
    end
  end

  private

  # check the `service-id` specific constraint first to be more granular
  def constraint_value constraint_name
    annotation_value("#{@authenticator_name}/#{@service_id}/#{constraint_name}") ||
      annotation_value("#{@authenticator_name}/#{constraint_name}")
  end

  def annotation_value name
    annotation = @role_annotations.find { |a| a.values[:name] == name }

    # return the value of the annotation if it exists, nil otherwise
    if annotation
      @logger.debug(LogMessages::Authentication::RetrievedAnnotationValue.new(name))
      annotation[:value]
    end
  end
end
```

##### Authentication request Application Identity

The input for this class will be built in each authenticator as it differs
between them. For simplicity, the class will receive the `constraints` hash
as an input. We should challenge that to find a better way.
```
class AuthenticationRequestApplicationIdentity
  attr_reader :constraints

  def initialize(constraints:)
    @constraints = constraints
  end
end
```

#### ValidateApplicationIdentity class

This class will use the classes defined above to validate the Application Identity.

```
ValidateApplicationIdentity ||= CommandClass.new(
  dependencies: {
    host_application_identity_class: HostApplicationIdentity
  },
  inputs:       %i(
    authenticator_name
    service_id
    host_annotations
    permitted_constraints
    required_constraints
    non_permitted_combinations
    authentication_request_application_identity
  )
) do

  def call
    extract_application_identity_from_host
    verify_application_identity_configuration
    verify_application_identity_matches_authentication_request
  end

  def extract_application_identity_from_host
    @host_application_identity_class.new(
      authenticator_name: @authenticator_name, 
      service_id: @service_id, 
      role_annotations: @host_annotations, 
      permitted_constraints: @permitted_constraints,
    )
  end

  def verify_application_identity_configuration
    # verify that `@host_application_identity_class.constraints.keys` contains
    # all members of `@required_constraints` and do not have more than one
    # member of `@non_permitted_combinations`
    #
    # Note: this can be extracted to another CommandClass 
  end

  def verify_application_identity_matches_authentication_request
    # iterate over `@host_application_identity_class.constraints` 
    # and verify each value matches the corresponding one in 
    # `@authentication_request_application_identity.constraints`
    #
    # Note: this can be extracted to another CommandClass 
  end
end
```

A call to this class will be made in the relevant Authenticator class. For
example, the Azure Authenticator class will look roughly like this:
 
```
module Authentication
  module AuthnAzure

    Authenticator = CommandClass.new(
      dependencies: {
        <other dependencies>,
        resource_class:             ::Resource
        authentication_request_application_identity_class: AuthenticationRequestApplicationIdentity
        validate_application_identity: ValidateApplicationIdentity.new,
      },
      inputs:       [:authenticator_input]
    ) do

      def call
        <perform other authentication steps>
        validate_application_identity
      end

      private
      
      def validate_application_identity
        @validate_application_identity.call(
          authenticator_name: @authenticator_input.authenticator_name
          service_id: @authenticator_input.service_id
          host_annotations: role.annotations
          permitted_constraints: %w(
                                     subscription-id
                                     resource-group
                                     user-assigned-identity
                                     system-assigned-identity
                                 )
          required_constraints: %w(
                                    subscription-id
                                    resource-group
                                 )
          non_permitted_combinations: %w(
                                         user-assigned-identity
                                         system-assigned-identity
                                       )
          authentication_request_application_identity: @authentication_request_application_identity_class.new(
            constraints: constraints_from_authentication_request
          )
        )
      end

      def constraints_from_authentication_request
        return @constraints_from_authentication_request if @constraints_from_authentication_request

        @constraints_from_authentication_request = {
          subscription_id: xms_mirid.subscriptions,
          resource_group:  xms_mirid.resource_groups
        }

        if xms_mirid.providers.include? "Microsoft.ManagedIdentity"
          @constraints_from_authentication_request[:user_assigned_identity] = xms_mirid.providers.last
        else
          @constraints_from_authentication_request[:system_assigned_identity] = @oid_token_field
        end

        @constraints_from_authentication_request
      end

      # @xms_mirid_token_field is extracted from the request body
      def xms_mirid
        @xms_mirid ||= XmsMirid.new(@xms_mirid_token_field)
      end

      def role
        @role ||= @resource_class[role_id]
      end
  end
end
```
 
## Application Identity stored in the host's ID

As mentioned in the beginning of the doc, we made an assumption that
Application Identities can be defined only in the host's annotations. 
However, in the K8s Authenticator it can be done also in the host's ID, to maintain
backwards-compatibility. For now it is just one authenticator out of two that
implements the Application Identity method but once we grow and have more
authenticators (e.g AWS Authenticator) then it will make less sense to
handle Application Identities defined in host IDs in the general classes.

To solve that, we can perform some manipulation inside the K8s Authenticator.
Before we call `ValidateApplicationIdentity` and pass into it the host's
annotations, we will check where the Application Identity is defined (as we
do [here](/app/domain/authentication/authn_k8s/application_identity.rb) in
the method `application_identity_in_annotations?`). If it's in the
annotations then we have no problem and we can pass the annotations to 
`ValidateApplicationIdentity`. If not, we can take the host ID and build a host
annotations object from it. For example, if the host ID is 
`namespace-1/service_account/service-account-1` then we will add to the host
annotations map 2 fields:
  - `authn-k8s/namespace: namespace-1`
  - `authn-k8s/service-account: service-account-1`
  
As a bonus, we may even add these annotations permanently to the host so next
time it tries to authenticate we won't need to do this manipulation. 
