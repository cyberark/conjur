# Solution Design - Authenticator as a Plugin

## Table of Contents

- [Problem Statement](#problemstatement)
- [Goals](#goals)
- [Implementation Steps](#implementationsteps)


## Problem Statement

Currently adding new authenticator type in Conjur / DAP requires code changes in Conjur.

Thus is only possible to external users by code contribution to Conjur, and impossible for a concrete DAP version (which uses predefined Conjur version)

Adding an ability to implement authenticator as an external plugin will allow our customers to implement authenticators of their own without changing Conjur codebase 

and without being familiar with Ruby / Conjur

## Goals
Create programmatic / configurational hooks in Conjur, which will allow to incorporate external authenticator as a plugin to Conjur
Make authenticator addition to be possible for customers
Preserve set of authenticators that exist in Conjur
Provide set of parameters for plugin-based authenticators per user decision

## Implementation Steps
- Identify the functional blocks that are common to all authenticators and split them into 2 kinds
  Blocks that are not going to be programmed by plugin (example: set / get authenticator in DB)
  Blocks that should be programmed by plugin (example: validate methods)
- Verify that base blocks inside Conjur are well separated from authenticator-specific blocks inside Conjur. 
- If they are not - take steps to make them such
- Define hook to load external authenticators
- Define hook to provide external authenticator parameters (probably in yaml)
- Define hook for "validate" step of external authenticator (should contain a pointer to function / executable)
- Verify that configuration of external authenticator is possible in Conjur
- Implement and test sample external authenticator
