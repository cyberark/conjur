# Authenticator Architecture v2 - Revision 2

## Objective

Simplify the effort required to develop a new authenticator by moving common checks external.

## Overview

```puml


|Authentication Controller|
start
  :Authentication Request;
|Authentication Handler|
  :Identify Authenticator Type;
  :Whitelisted?;
|Authenticator Repository|
  :Load Authenticator (by type and service ID);
  :[Custom][AuthenticatorContract]\n
  Validate Authenticator Configuration;
|Strategy|
  :[Custom][Strategy] \n
    * Validate authentication workload\n
    * Identify target role;
|Authenticator Role Repository|
  :Find role by identifier;
  :[Custom][RoleContract]\n
    * Validate annotation restrictions;
|Authentication Handler|
  :Verify role's authentication permission;
  :Generate authentication token;
  :Audit success/failure;
  :Return token;
|Authentication Controller|
  :Render Token;
end
```
