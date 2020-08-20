**Note**: This design document has been ported from the original document
[here](https://github.com/cyberark/conjur/issues/524).

# Background
The need to write this solution design arises from the problem that was raised as part of secret provider phase II implementation.

The problem is getting error upon authenticate call from secret provider to conjur. The same error appears in all K8S authenticator client usages

# Issue description
The root cause of the issue that was found appears to be that K8S auth client tries to access to cert file that is written from Conjur K8S Authn by K8S API before this cert file appears / is ready

The reason for this behaviour is that the flow returns to K8S Authn Client without waiting for cert file to be fully written, and K8S Auth client proceeds with flow to read a file - and then we get an error.

# Solution
The solution should be that K8S Authn Client should wait until and event that says that cert file is ready for use will arrive - and only then it should proceed to read it

In case that the expected event does not arrive after timeout - error must be issued and the flow will proceed without reading cert file

# Design
https://ca-il-confluence.il.cyber-ark.com/download/attachments/327388612/Authenticator%20Bug%20Sequence%20Diagam.jpeg?version=1&modificationDate=1597664913408&api=v2

The addition to the current design is WaitUntilWrittenOrTimeout call. It should be executed per new flag sent into the InjectClientCert command (in order to stay backward compatible)

New env variable will be added to AuthnClient process for the flag above

It also will be passed as an argument to AuthClient library

# Alternative Solutions

Waiting in AuthnClient for event when cert file is created
Polling from AuthnClient on cert file

Disadvantage of both above alternatives is that the file creation handling is not localized in a single place

# Backwards compatibility

See flag above

# Performance

In case performance is an issue - flag above will be off

# Affected Components
Conjur, AuthnClient, Secret Provider

# Test plain
Successful K8S authn	K8S authenticator	Authenticate from secret provider	Success	No errors
Failed K8S authn	K8S authenticator	Authenticate with wrong cert from secret provider	Failure	Error
Failed to create cert file	K8S authenticator	Authenticate from secret provider	Timeout	Error:Timeout

# Logs

File not found after timeout	File not found after timeout
