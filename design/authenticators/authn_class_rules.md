# Authenticator classes reflection rules and `authn-jwt`

## Background

Each authenticator must conform to the following rules:

- Authenticator module name must to start with `Authn` prefix
- Authenticator module must have a class named `Authenticator`
- `Authenticator` class must have `valid?` method

All rules together define authenticator appearance in `installed` authenticators of the `authenticators` rest call.

`valid?` is an interface method that's invoked duding [general authentication flow](app/domain/authentication/authenticate.rb#23)

The general authentication flow does not suite needs of all existing authenticators
from both flow and authentication parameters view.
Today it's often solved by adding degenerate `valid?` method to an `Authenticator` class.
It makes code less readable and can cause [bugs](https://github.com/cyberark/conjur/pull/2348/commits/7db01a6ab8a19f33c157c519ff903b11a392a8aa).  

## Issue Description

A recently introduced `authn-jwt` authenticator does not appear in `installed` authenticators
of the `authenticators` rest call. It has its own authentication flow hence it has no `valid?` method.

## Solution

### 1. Define `valid?` method in `AuthnJwt::Authneticator` class

The method will throw [NoMethodError](https://ruby-doc.org/core-2.5.0/NoMethodError.html).
Also see the [blogpost](https://oleg0potapov.medium.com/ruby-notimplementederror-dont-use-it-dff1fd7228e5).

proc:

- less intrusive solution

cons:

- make the class code less readable
- may lead to unexpected behaviour and bugs

### 2. Remove the rule requires from authenticator to have `valid?` method [implemented]

Make appropriate changes in `Authentication::AuthenticatorClass` [class](app/domain/authentication/authenticator_class.rb)

proc:

- makes an Authenticator contract more clear
- reduces complexity of future authenticators

cons:

- makes contract weaker?

  Actually the reflection rules are looking for the first level class in the module.
  Ruby prioritizes classes with respective file name, means if there are multiple files
  with the same class definition `MyClass` for example ruby will "choose" the class from `myclass.rb` file.
  In our use-case all `Authenticator` classes are in `authenticator.rb` files and it's
  highly unlikely that we somehow will break this convention. In any case it will behave
  the same with or without `valid?` method rule. 

### 3. Rethink this area from scratch and to create a new contract meat all known needs

From my perspective this approach does not worth ROI at the moment and
should be taken as a part of core-authenticators separation if occur.
