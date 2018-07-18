# Rotators - Overview

A rotator changes the value of a secret or group of related secrets at fixed time intervals -- every 10 minutes, every day, every 2 weeks, etc.  This fixed time interval is called the time-to-live, or ttl.  It specifies how long a secret is allowed to "be alive."  When its ttl is up, it "dies" and is rotated to a new secret.

Conjur rotators update these secrets in two places: within the secure Conjur database, and on the "target" machine -- the machine in the real world that is protected by the secret.  This could be a postgres database, an Amazon AWS account, or anything anything else with protected access.  Thus Conjur rotators ensure two things:

1. That secrets are rotated according to their ttl (to within 1 second of accuracy)
2. That the secrets on the target machine and Conjur are always in sync

# Using Rotators

[Documentation for using rotators](https://docs-staging.conjur.org/Version%205/en/Content/Operations/Services/rotation.html?Highlight=rotation)

# Development

The sections below are relevant only to developers wishing to create new rotators or maintain existing ones.

# Creating new rotators

## Overview

Adding new rotators is easy: It requires no updates to existing code.  Follow these steps:

1. **Create a subdirectory under `/app/domain/rotation/rotators`** 
    Give your subdirectory a name that describes your rotator.  If you are implementing multiple related rotators, give the subdirectory a suitable umbrella name.  For example, the AWS rotator is in the `aws` directory, and the Postgres rotator is in the `postgresql` directory.
2. **Add any supporting classes or files to your subdirectory**
    Optional, but you may have helper classes, data files, etc.
3. **Implement your rotator class**
    Details about the expected interface are described below.

**NOTE:** Any valid rotator class added as described above will be automatically loaded during server bootup and available for variables to use via the policy `rotation/rotator` annotation. 

## Rotator Interface

The rotator itself is simply a class with:

1. An initializer that has zero _required_ arguments.
2. A `rotate(facade)` method

The `rotate(facade)` method will be called whenever a variable's ttl has expired.

The rotator communicates with Conjur _exclusively through the facade_, which is described below.

## The Conjur Facade

Rotators should never call any code outside of their own subdirectories, _other than_ methods on the `facade` object passed to `rotate`.  Consider the facade the rotator's API to the Conjur system.

The `facade` object passed to `rotate` itself has a simple interface consisting of 4 methods:

1. `rotated_variable` -- returns an object representing the variable being rotated, an instance of `RotatedVariable`.  

    A `RotatedVariable` variable has 3 convenience methods for extracting the parts that make up a fully-qualified variable resource id: `account`, `kind` (this will always be "variable"), and `name` (the unqualified name of the variable itself).  

    In addition, it provides the convenience method `sibling_id(name)`, which, given an unqualified variable name, will return a fully-qualified resource id, using the account and kind of the object's instance.  That is, assuming the variable name is a sibling of the current object.  This is useful when updating a group of related variables.

2. `annotations` -- returns a hash of the names and current values of all annotations on the rotated variable instance.

3. `current_values(variable_ids)` -- `variable_ids` is an array of fully-qualified Conjur variable resource ids.  The method returns a hash whose keys are the variable ids passed in, and whose values are the current values of those variables.

    This is used to get the current values of variables related to the rotated variable.  For example, in a database rotator, the password is the main rotated variable.  However, it also has a related username and url, whose values are also needed, and which are defined as sibling variables in the Conjur policy.

4. `update_variables(new_values, &rotator_code)` -- This is the inverse of `current_values`: it takes a hash whose keys are fully-qualified variable resource ids, and whose values are the desired new values of those variables.

    It can also optionally be provided with a block of code.  That code and the variable updates occur inside of a single transaction.  If the code errors, the updates will not occur, and vice-versa.

    This allows rotators to ensure that the secret update on the target machine and the update of the associated Conjur variable occur as a single unit of work, and are always in sync.
