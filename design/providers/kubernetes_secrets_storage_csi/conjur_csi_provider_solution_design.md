# Solution Design - CyberArk Conjur Provider for Secret Store CSI Driver

- [Glossary](#glossary)
- [Useful links](#useful-links)
- [Issue description](#issue-description)
- [Out of scope](#out-of-scope)
- [Solution](#solution)
  - [UX](#ux)
    - [SecretProviderClass](#secretproviderclass)
    - [Helm Charts](#helm-charts)
  - [Development Tasks](#development-tasks)
    - [Implementation Tasks](#implementation-tasks)
    - [Testing Tasks](#testing-tasks)
    - [Documentation Tasks](#documentation-tasks)
    - [Release Tasks](#release-tasks)
    - [Continuous Improvement](#continuous-improvement)
  - [Design](#design)
    - [Class diagram](#class-diagram)
    - [User flow](#user-flow)
  - [Implementation plan](#implementation-plan)
    - [Designs](#designs)
    - [Implementation](#implementation)
    - [Testing](#testing)
    - [Nice-to-haves](#nice-to-haves)
- [Backwards compatibility](#backwards-compatibility)
- [Performance](#performance)
- [Affected Components](#affected-components)
- [Security](#security)
- [Test Plan](#test-plan)
- [Logs](#logs)
- [Documentation](#documentation)
- [Open questions](#open-questions)

## Glossary

- **Kubernetes**: An open-source system for automating deployment, scaling, and management of containerized applications.

- **CyberArk Conjur**: A secrets management service that secures secrets used by machines and users, providing high scalability, flexibility, and a strong security model.

- **Container Storage Interface (CSI) Driver**: A standard for exposing arbitrary block and file storage systems to containerized workloads on Container Orchestration Systems.

- **Secrets Store CSI Driver**: A Kubernetes Container Storage Interface (CSI) Driver that provides secure access to secrets from secret stores. It operates as a bridge between the Kubernetes and the Secret Store (CyberArk Conjur, in our case).

- **authn-jwt**: An authentication method used by Conjur that authenticates the service via JSON Web Tokens (JWT). In this scenario, it uses the service account token of the Kubernetes workload to authenticate.

- **Helm**: The package manager for Kubernetes that simplifies deployment and configuration of applications on Kubernetes.

## Useful links

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [CyberArk Conjur Documentation](https://docs.conjur.org/Latest/en/Content/Home.htm)
- [Secrets Store CSI Driver](https://github.com/kubernetes-sigs/secrets-store-csi-driver)
- [CSI Specification](https://github.com/container-storage-interface/spec)
- [Helm Documentation](https://helm.sh/docs/)

## Issue description

The task at hand is to implement a CyberArk Conjur provider for the Kubernetes Secrets Store CSI driver. This provider will authenticate with Conjur using the Kubernetes workload's service account token via authn-jwt, and fetch secrets from Conjur. These secrets are then made available to Kubernetes pods, providing a seamless and secure method of managing secrets.

## Out of scope

The following are outside the scope of this design:

- Details on setting up CyberArk Conjur.
- Integration with other Kubernetes CSI drivers.
- Management of secrets within CyberArk Conjur.

## Solution

The proposed solution aims to implement a CyberArk Conjur provider for Kubernetes Secrets Store Container Storage Interface (CSI) driver. This solution allows Kubernetes pods to seamlessly fetch secrets from a Conjur instance using the service account token via the `authn-jwt` authenticator.

The core of the CyberArk Conjur provider is a gRPC server that listens on a Unix domain socket. It implements the `CSIDriverProviderServer` interface, which is defined by the Secrets Store CSI Driver project and located in the `sigs.k8s.io/secrets-store-csi-driver/provider/v1alpha1` package.

The `CSIDriverProviderServer` interface includes the `Mount` and `Version` methods:

1. `Mount`: Invoked by the Secrets Store CSI Driver during the volume mount phase. The `MountRequest` object passed to this method contains several important fields:

   - `Attributes`: A string containing JSON-encoded attributes. These attributes contain properties needed for the provider to fetch secrets, such as the `authnUrl` and secret IDs. This is a flexible mechanism that allows for a variable set of attributes based on the provider's requirements.

   - `Secrets`: A string containing JSON-encoded secrets. These secrets contain sensitive data such as the Kubernetes service account token, which is used for authenticating with Conjur via the `authn-jwt` authenticator.

   - `TargetPath`: The path where the Secrets Store CSI Driver expects the secrets files to be written. The provider is responsible for fetching the requested secrets and writing them to this path.

   - `Permission`: A string containing JSON-encoded file permissions. These are the permissions that should be applied to the files containing the secrets.

   The `Mount` method's responsibilities are to authenticate with the Conjur instance, fetch the secrets specified in the `Attributes`, write these secrets to files at the `TargetPath`, and then return a `MountResponse` to the Secrets Store CSI Driver. The `MountResponse` includes metadata about the fetched secrets, such as their IDs and versions.

2. `Version`: Invoked by the Secrets Store CSI Driver to discover the provider's version information. This method returns a `VersionResponse` object that includes the version of the provider protocol, and the name and version of the provider's runtime.

By implementing this gRPC server and the `CSIDriverProviderServer` interface, we can create a Conjur provider for the Kubernetes Secrets Store CSI Driver. This provider will handle fetching secrets from the Conjur instance and passing them back to the Secrets Store CSI Driver, which in turn makes them available to Kubernetes workloads.

Helm charts will be created for deploying the CyberArk Conjur provider. This provides a streamlined, automated, and repeatable deployment process.

### UX

The user interaction with our solution will mainly be through Kubernetes manifests and Helm.

#### SecretProviderClass

`SecretProviderClass` is a Kubernetes custom resource that stores the secret provider configuration. The user will define a Kubernetes `SecretProviderClass` object that refers to the CyberArk Conjur provider and specifies necessary parameters for it. This would look something like the following:

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: db-credentials
spec:
  provider: conjur
  parameters:
    authnUrl: https://conjur-auth.some-org.com
    applianceUrl: https://conjur.some-org.com
    account: some-org
    authnLogin: path/to/some-policy/some-host
    policyPath: path/to/some-policy/with-secrets # defaults to /
    secrets: |
      - db_username: "db/username" # relative to policyPath, otherwise if it starts with / then it is absolute
      - db_password: "db/password"
```

In this example, the `SecretProviderClass` named `db-credentials` is using the CyberArk Conjur provider. The parameters section contains the `authnUrl`, the `applianceUrl` and a list of secrets to fetch from Conjur. The secrets are identified by their paths in Conjur  (i.e. `db/username` and `db/password`). The `policyPath` parameter can be used to specify the policy branch from which to resolve relative secret paths.

A pod that wants to use these secrets would reference the `SecretProviderClass` in its volumes definition like so:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: mycontainer
    image: myimage
    volumeMounts:
    - name: secrets-store-inline
      mountPath: "/mnt/secrets-store"
      readOnly: true
  volumes:
  - name: secrets-store-inline
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "db-credentials"
```

In this example, the Pod `mypod` mounts a volume at `/mnt/secrets-store`. This volume is provided by the Secrets Store CSI driver and is configured to fetch secrets as defined by the `db-credentials` SecretProviderClass. The secrets fetched by the driver will be written to files in this volume. For instance, the secret `db/username` will be written to the file `/mnt/secrets-store/db_username` in the pod's filesystem.

#### Helm Charts

We'll use Helm charts to manage the deployment of our Conjur provider, which will simplify the deployment process and make it more reliable.

The Helm chart will encapsulate the details of the deployment configuration, including the definition of deployment resources, configuration of the Conjur provider, and the necessary Kubernetes roles and role bindings.

### Development Tasks

The implementation of the CyberArk Conjur provider for the Kubernetes Secrets Store CSI Driver will require several tasks to be completed. These tasks can be grouped into several categories: implementation, testing, documentation, and release.

#### Implementation Tasks

1. **Implement the Conjur Provider**: Develop a Go-based application that uses the CyberArk Conjur API to authenticate and fetch secrets. This application should implement the `CSIDriverProviderServer` interface, which includes the `Mount` and `Version` methods. These methods will need to communicate with the CyberArk Conjur API to fetch secrets and return them to the Secrets Store CSI Driver.

2. **Create the Helm Charts**: Develop the necessary Kubernetes resource definitions (Deployment, Service, etc.) and values files to manage the deployment of the Conjur provider. This Helm chart will allow users to easily deploy and configure the Conjur provider in their Kubernetes clusters.

3. **Integration with CyberArk Conjur**: The logic for the provider to authenticate with the Conjur API and fetch secrets needs to be developed. This will involve using the `authn-jwt` authenticator for authentication with the workload service account token and making API calls to fetch secrets.

4. **Secret File Writing**: The logic for writing the fetched secrets to files at the path specified by the Secrets Store CSI Driver needs to be implemented.

5. **Error Handling**: Robust error handling should be implemented. This includes handling errors during authentication, secret fetching, and file writing. It also includes returning informative error messages to the Secrets Store CSI Driver.

6. **Logging**: Implement logging throughout the provider to assist with debugging and troubleshooting.

7. **Implement Health Check**: Implement a health check mechanism to monitor the status of the provider. This could involve creating a `/healthz` endpoint in the provider's application that returns HTTP 200 when the provider is running properly, or using Kubernetes liveness and readiness probes.

8. **Setup Linting**: Setup linting tools for Go (such as `golangci-lint` or `go vet`) to identify syntactic errors, problematic constructs, and departures from style guidelines. This will help in maintaining high-quality, idiomatic Go code.

9. **Setup Continuous Integration (CI)**: Setup a CI/CD pipeline to automatically build the provider, run tests, perform linting, and create Docker images on each commit or pull request. This will ensure code quality and prevent integration issues.

#### Testing Tasks

1. **Unit Testing**: Develop unit tests for all core functionality, including authentication, secret fetching, file writing, and error handling. These tests should mock the Conjur API and file system.

2. **Integration Testing**: Develop integration tests that run against a live Conjur instance and a Secrets Store CSI Driver instance. These tests should cover both successful operation and failure modes.

3. **Performance Testing**: Develop performance tests to ensure that the provider operates efficiently and does not negatively impact Kubernetes workload performance.

#### Documentation Tasks

1. **User Guide**: Write a user guide explaining how to use the CyberArk Conjur provider with the Secrets Store CSI Driver. This should include examples of how to specify secrets in Kubernetes workload manifests.

2. **Installation Guide**: Write a guide detailing how to install the CyberArk Conjur provider and integrate it with a running instance of the Secrets Store CSI Driver.

3. **Troubleshooting Guide**: Write a guide providing solutions for common problems that may occur when using the CyberArk Conjur provider.

#### Release Tasks

1. **Code Review**: Conduct a thorough code review of the entire provider. This should include a review of the code itself, the unit tests, and the integration tests.

2. **Security Audit**: Conduct a security audit to ensure that the provider securely handles sensitive data such as the service account token and the fetched secrets.

3. **Version Tagging**: Tag the first stable release of the provider. Use Semantic Versioning for version numbers.

4. **Release Announcement**: Write and publish a release announcement. This should include an overview of the CyberArk Conjur provider, links to the installation guide and user guide, and information about how to get support.

5. **Package the Release**: Package the provider as a Helm chart or an Operator for easy installation in Kubernetes clusters.

#### Continuous Improvement

1. **Feedback and Improvement**: Post deployment, feedback from users will be necessary to make continuous improvements to the solution. Set up channels for users to provide feedback and report issues. Implement a process for triaging and addressing this feedback in future releases??

### Design

#### Class diagram

[Class Diagram Placeholder]

#### User flow

1. The user deploys the CyberArk Conjur provider using Helm. This involves configuring the Helm chart with the necessary parameters and deploying it to their Kubernetes cluster.
1. The user create an instance of the `SecretProviderClass` custom resource object for the CyberArk Conjur provider.
1. The user specifies, inside the Kubernetes workload manifests, the usage of the CyberArk Conjur provider by reference to the `SecretProviderClass` object.
1. The user deploys the workload.
1. When a pod associated with the workload starts, the Secrets Store CSI driver initiates communication with the CyberArk Conjur provider via the gRPC interface.
1. The CyberArk Conjur provider authenticates to the Conjur instance via authn-jwt using the service account token of the workload.
1. The CyberArk Conjur provider fetches the requested secrets from Conjur.
1. The fetched secrets are mounted into the pod's file system via the Secrets Store CSI driver.
1. The application in the pod can then consume the secrets.

### Implementation plan

#### Designs

- Design the UI/UX of the CyberArk Conjur provider e.g. the mechanism for specifying the secrets to fetch and where to write them

#### Implementation

- Implement the CyberArk Conjur provider according to the design.
- Create Helm charts for the deployment of the CyberArk Conjur provider.
- Implement logging and error handling in the CyberArk Conjur provider.

#### Testing

- Develop and run unit tests for the CyberArk Conjur provider.
- Develop and run integration tests that involve the Secrets Store CSI driver and the CyberArk Conjur provider.
- Develop and run end-to-end tests that cover the entire secret retrieval process, from Kubernetes workloads to fetching secrets from CyberArk Conjur.

#### Nice-to-haves

Nice-to-haves are additional features that, while not strictly necessary, could significantly enhance the user experience and the utility of the provider.
These features will likely not be included in the initial release of the CyberArk Conjur provider, but could be implemented in subsequent releases based on user feedback and the evolving needs of the Kubernetes community.

Here are some of the potential nice-to-have features:

1. **Reference Other Kubernetes Resources**: This feature would allow users to point the CyberArk Conjur provider to other Kubernetes resources. For instance, users could point to a 'golden' ConfigMap that contains Conjur configuration data. This would provide a dynamic and centralized way to manage Conjur configurations, and would be especially useful in large deployments where multiple applications are interacting with Conjur.

2. **Configurable Secret Templates**: Similar to the 'push-to-file' functionality in the Conjur Secrets Provider, the CyberArk Conjur provider could offer the ability to configure templates for writing secrets. This would give users the flexibility to customize the structure and format of the secret data that is written to their applications. For example, a user might want secrets to be written as a JSON object, as key-value pairs, or in another format that suits their application.

3. **Supported Provider Status**: While it's important for the Conjur provider to be functional and reliable, achieving the status of a 'supported provider' in the Kubernetes Secrets Store CSI Driver project would be a significant accomplishment. This would entail meeting certain criteria set by the Kubernetes community, including thorough documentation, robust testing, active maintenance, and more. Achieving this status would give users greater confidence in using the Conjur provider, and it could lead to increased adoption and feedback, helping to drive continuous improvement of the provider.

4. **Support for Other Conjur Authenticators**: Currently, our solution is designed to use the `authn-jwt` authenticator with the workload's service account token. However, it could be beneficial to support other Conjur authentication methods, such as `authn-k8s`. This would provide more flexibility for users with different authentication requirements and could potentially enhance security by allowing more complex authentication schemes. The implementation would involve adding additional logic to the provider to handle the various authenticators and additional configuration options to specify which authenticator to use.

## Backwards compatibility

The solution is implemented as a new provider for the Secrets Store CSI Driver and will not impact existing providers or Kubernetes workloads not using this new provider.

## Performance

Performance of this solution depends on the responsiveness of the CyberArk Conjur instance and the network latency between the Kubernetes cluster and the Conjur instance. The CyberArk Conjur provider itself introduces minimal overhead as it simply passes secrets from Conjur to the Secrets Store CSI driver.

## Affected Components

- **New Component:** CyberArk Conjur provider for Secrets Store CSI driver.
- **Existing Component:** Secrets Store CSI driver.

## Security

The solution upholds high standards of security:

1. Communication between the CyberArk Conjur provider and Conjur happens over a secure channel.
2. `authn-jwt` ensures strong authentication with the use of cryptographically verifiable service account tokens.

## Test Plan

A comprehensive testing strategy will be employed:

1. **Unit tests:** Test individual functions and methods in the CyberArk Conjur provider.
2. **Integration tests:** Test the interaction of the CyberArk Conjur provider with the Secrets Store CSI driver and Conjur.
3. **End-to-end tests:** Test the entire workflow from a Kubernetes workload to fetching secrets from Conjur.

## Logs

Both the Secrets Store CSI driver and the CyberArk Conjur provider will generate logs. These will provide insights into authentication, secret retrieval, and error conditions. We only have explicit control of the provider logs.

## Documentation

The documentation will cover:

1. The deployment and configuration of the CyberArk Conjur provider.
2. The creation and usage of a `SecretProviderClass` that utilizes the CyberArk Conjur provider.
3. The configuration of Kubernetes workloads to use the CyberArk Conjur provider.

## Open questions

- Does the mount path have to be `/mnt/secrets-store` ?
- What's the best way to configure things like CA certs for the provider etc. ? Perhaps allowing the `SecretProviderClass` to reference other Kubernetes resources such `ConfigMap` or `Secret` is the answer
- What are our options for supporting authentication via authenticators other than authn-jwt ?
- What is the upgrade strategy for the CyberArk Conjur provider deployed via Helm?
- How to handle secret rotation in CyberArk Conjur?
- How should the CyberArk Conjur provider be deployed and managed across multiple Kubernetes clusters? Should there be a separate instance of the provider for each cluster, or can a single instance serve multiple clusters?
- How should the provider handle errors, such as failure to communicate with the Conjur server or failure to authenticate? What recovery mechanisms should be in place?
- How will the provider's operations be monitored and logged? What kind of visibility will administrators have into the provider's activities, and how can potential issues be identified and diagnosed?
- How will the provider perform under heavy load? What are the limitations in terms of the number of secrets it can manage or the rate at which secrets can be fetched?
- Will the provider support multiple formats for secrets, such as plain text, JSON, YAML, etc.? How will the desired format be specified?
- How will access to the provider be controlled? What measures will be in place to prevent unauthorized access?
- Will the provider be compatible with all versions of Kubernetes and Conjur, or are there specific version requirements?
