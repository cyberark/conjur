# Conjur Kubernetes Authentication (`authn-k8s`) Troubleshooting Guide

## Table of Contents

- [Overview](#overview)
- [Troubleshooting Kubernetes Authentication on Conjur Open Source](#troubleshooting-kubernetes-authentication-on-conjur-open-source)
  * [Prerequisites for Troubleshooting on Conjur Open Source](#prerequisites-for-troubleshooting-on-conjur-open-source)
  * [Before We Begin Troubleshooting: Some Handy Tools and How-Tos](#before-we-begin-troubleshooting-some-handy-tools-and-how-tos)
  * [Step-by-Step: Verifying Your Conjur Authentication Configuration](#step-by-step-verifying-your-conjur-authentication-configuration)
  * [Some Useful Conjur Commands](#some-useful-conjur-commands)
  * [Failure Conditions and How to Troubleshoot](#failure-conditions-and-how-to-troubleshoot)
    + [Conjur server cannot access application Kubernetes Resources](#conjur-server-cannot-access-application-kubernetes-resources)
    + [Conjur Kubernetes Authenticator is not enabled](#conjur-kubernetes-authenticator-is-not-enabled)
    + [Conjur appliance URL is set incorrectly](#conjur-appliance-url-is-set-incorrectly)
    + [Certificate not valid for domain name in Conjur appliance URL](#certificate-not-valid-for-domain-name-in-conjur-appliance-url)
    + [Invalid Response to Certificate Signing Request](#invalid-response-to-certificate-signing-request)

## Overview

This guide presents some tips and guidelines for troubleshooting the
functionality of
[Conjur Kubernetes authentication (`authn-k8s`)](https://docs.conjur.org/Latest/en/Content/Operations/Services/k8s_auth.htm)
on a [Conjur](https://docs.conjur.org/) cluster.

## Troubleshooting Kubernetes Authentication on Conjur Open Source

This section presents some tips and guidelines for troubleshooting
[Conjur Kubernetes authentication (`authn-k8s`)](https://docs.conjur.org/Latest/en/Content/Operations/Services/k8s_auth.htm)
specifically on a [Conjur Open Source](https://docs.conjur.org/) cluster that has
been deployed via the
[Conjur Open Source Helm Chart](https://github.com/cyberark/conjur-oss-helm-chart/conjur-oss).

The intended audience for this section of the guide is anyone who encounters
issues when deploying Kubernetes applications that make use of Conjur
Kubernetes authentication brokers or clients such as the following to
authenticate with Conjur:

- [Secretless Broker](https://github.com/cyberark/secretless-broker) sidecar
  container
- [Conjur Kubernetes Authenticator Client](https://github.com/cyberark/conjur-authn-k8s-client)
  as either a sidecar or init container

### Prerequisites for Troubleshooting on Conjur Open Source

This section of the guide assumes that you have:

- [`kubectl`](https://kubernetes.io/docs/reference/kubectl/overview/)
  access to your Kubernetes cluster.

  <details>
    <summary>Click to expand installation examples.</summary>

    #### Installing `kubectl` on Linux

    ```sh-session
        # Download the binary, make it executable, and move it to your PATH
        curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.19.0/bin/linux/amd64/kubectl
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin
    ```

    #### Installing `kubectl` on MacOS

    ```sh-session
        brew install kubernetes-cli
    ```

  </details>

- [`helm`](https://helm.sh/docs/intro/install/) client version 3 or newer.

  <details>
    <summary>Click to expand installation examples.</summary>

    #### Installing `helm` on Linux:

    ```sh-session
        # Download the release tar file, unpack it, and copy the client to your PATH
        mkdir -p ~/temp/helm-v3.3.1
        cd ~/temp/helm-v3.3.1
        helm_tar_file=helm-v3.3.1-linux-amd64.tar.gz
        curl https://get.helm.sh/"$helm_tar_file" --output "$helm_tar_file"
        tar -zxvf "$helm_tar_file"
        sudo mv linux-amd64/helm /usr/local/bin
    ```

    #### Installing `helm` on MacOS:

    ```sh-session
        brew install helm
    ```
  </details>

- [`conjur` CLI](https://github.com/cyberark/conjur-cli) access to your
  [Conjur Open Source](https://docs.conjur.org/) server.

  If you don't have this set up already, see the
  [Creating a Conjur CLI Pod](#creating-a-conjur-cli-pod) section below.

### Before We Begin Troubleshooting: Some Handy Tools and How-Tos

Before proceeding to the step-by-step guide to verifying your Conjur
authentication, here are a few tools and "how-tos" that might come in handy
while following the troubleshooting steps.

#### Creating a Conjur CLI Pod

In some cases, it may be helpful to create a Conjur CLI pod in your
Kubernetes cluster, and create a `conjur` command alias that executes
commands via that Conjur CLI pod.

For example, you may be exploring Conjur Open Source and Kubernetes authentication
on a [Kubernetes-in-Docker (KinD)](https://kind.sigs.k8s.io/) or
or [MiniKube](https://minikube.sigs.k8s.io/docs/) cluster, and you prefer
not to install a software load balancer such as
[MetalLB](https://metallb.universe.tf/).

<details>
  <summary>Click to see an example of how to deploy a Conjur CLI pod.</summary>

  ```sh-session
  # Set environment. Modify as necessary to match your setup.
  HELM_RELEASE=conjur-oss
  CONJUR_NAMESPACE=conjur-oss

  # Create a Conjur CLI pod in the Conjur Open Source namespace
  CLI_IMAGE=cyberark/conjur-cli:5-latest
  echo "
  ---
  apiVersion: apps/v1
  kind: Deployment
  metadata:
    name: conjur-cli
    labels:
      app: conjur-cli
  spec:
    replicas: 1
    selector:
      matchLabels:
        app: conjur-cli
    template:
      metadata:
        name: conjur-cli
        labels:
          app: conjur-cli
      spec:
        serviceAccountName: conjur-oss
        containers:
        - name: conjur-cli
          image: $CLI_IMAGE
          imagePullPolicy: Always
          command: ["sleep"]
          args: ["infinity"]
  " | kubectl create -n "$CONJUR_NAMESPACE" -f -

  # Retrieve Conjur admin password
  CONJUR_POD="$(kubectl get pods -n $CONJUR_NAMESPACE -l app=conjur-oss \
          -o jsonpath='{.items[0].metadata.name}')"
  CONJUR_ACCOUNT="$(kubectl exec -n $CONJUR_NAMESPACE $CONJUR_POD -c conjur-oss -- printenv \
          | grep CONJUR_ACCOUNT \
          | sed 's/.*=//')"
  ADMIN_PASSWORD="$(kubectl exec -n $CONJUR_NAMESPACE $CONJUR_POD -c conjur-oss \
          -- conjurctl role retrieve-key $CONJUR_ACCOUNT:user:admin | tail -1)"

  # Initialize the Conjur CLI pod's connection to Conjur
  export CLI_POD="$(kubectl get pods -n $CONJUR_NAMESPACE -l app=conjur-cli \
          -o jsonpath='{.items[0].metadata.name}')"
  CONJUR_URL="https://conjur-oss.$CONJUR_NAMESPACE.svc.cluster.local"
  kubectl exec -n $CONJUR_NAMESPACE $CLI_POD -- bash -c "yes yes | conjur init -a $CONJUR_ACCOUNT -u $CONJUR_URL"
  kubectl exec -n $CONJUR_NAMESPACE $CLI_POD -- conjur authn login -u admin -p $ADMIN_PASSWORD 

  # Create a 'conjur' command alias 
  alias conjur="kubectl exec -n conjur-oss $CLI_POD -- conjur"
  ```
</details>

#### Creating a Pod for Curling From Inside the Cluster

Sometimes it is helpful to be able to run the `curl` command from inside
the Kubernetes cluster.

<details>
  <summary>Click to see an example of how to deploy a Conjur CLI pod.</summary>

  ```sh-session
  # Set environment. Modify as necessary to match your setup.
  CONJUR_NAMESPACE=conjur-oss

  # Create a 'pod-curl' pod in the Conjur Open Source namespace
  echo "
  ---
  apiVersion: v1
  kind: Pod
  metadata:
    name: pod-curl
    labels:
      name: pod-curl
  spec:
    containers:
    - name: alpine-curl
      image: wiremind/docker-alpine-curl-ca-certificates
      imagePullPolicy: Always
      command: ["sh", "-c", "tail -f /dev/null"]
      volumeMounts:
      - name: conjur-ca-cert
        mountPath: /usr/local/share/ca-certificates/conjur-ca-cert.crt
        subPath: conjur-ca-cert.crt
        readOnly: false
    volumes:
    - name: conjur-ca-cert
      secret:
        secretName: conjur-oss-conjur-ssl-ca-cert
        items:
        - key: tls.crt
          path: conjur-ca-cert.crt 
  " | kubectl create -n "$CONJUR_NAMESPACE" -f -

  # Wait for pod to become ready
  kubectl wait --for=condition=ready pod -n $CONJUR_NAMESPACE pod-curl --timeout 300s

  # Add the Conjur CA certificate to the pod's trusted CA certificates
  kubectl exec -it -n $CONJUR_NAMESPACE pod-curl -- update-ca-certificates

  # Create a 'pod-curl' command alias
  alias pod-curl="kubectl exec -n $CONJUR_NAMESPACE pod-curl -- curl"
  ```

  To test out curl access from within the Kubernetes cluster, try
  curling the `conjur-oss` service. For example:

  ```
  $ pod-curl -s https://conjur-oss."$CONJUR_NAMESPACE".svc.cluster.local | grep "Your Conjur"
      <p class="font-large">Your Conjur server is running!</p>
  $
  ```
</details>

#### Enabling Debug Logs for the Conjur Server

In the troubleshooting steps below, it sometimes helps to get more detailed
information by setting the log level to `debug` for the Conjur server before
reproducing an error.

  <details>
    <summary>Click to see an example of how to enable Conjur debug logging.</summary>

    ```sh-session
    # Set environment. Modify as necessary to match your setup.
    CONJUR_NAMESPACE=conjur-oss
    HELM_RELEASE=conjur-oss

    helm upgrade \
         -n "$CONJUR_NAMESPACE" \
         --reuse-values \
         --set logLevel=debug \
         "$HELM_RELEASE" \
         ./conjur-oss
    ```
  </details>

#### Collecting Conjur Logs

##### Collecting Conjur Server Logs

  <details>
    <summary>Click to see example of how to show Conjur server logs.</summary>

    ```sh-session
    # Set environment. Modify as necessary to match your setup.
    CONJUR_NAMESPACE=conjur-oss
    HELM_RELEASE=conjur-oss

    pod_name=$(kubectl get pods \
          -n "$CONJUR_NAMESPACE" \
          -l "app=conjur-oss,release=$HELM_RELEASE" \
          -o jsonpath="{.items[0].metadata.name}")
    kubectl logs -n "$CONJUR_NAMESPACE" "$pod_name" conjur-oss
    ```
  </details>

##### Collecting Conjur NGINX Container Logs

  <details>
    <summary>Click to see example of how to show Conjur NGINX container logs.</summary>

    ```sh-session
    # Set environment. Modify as necessary to match your setup.
    CONJUR_NAMESPACE=conjur-oss
    HELM_RELEASE=conjur-oss

    pod_name=$(kubectl get pods \
          -n "$CONJUR_NAMESPACE" \
          -l "app=conjur-oss,release=$HELM_RELEASE" \
          -o jsonpath="{.items[0].metadata.name}")
    kubectl logs -n "$CONJUR_NAMESPACE" "$pod_name" conjur-oss-nginx
    ```

  </details>

##### Collecting Conjur Postgres Pod Logs

  <details>
    <summary>Click to see example of how to show Conjur Postgres pod logs.</summary>

    ```sh-session
    # Set environment. Modify as necessary to match your setup.
    CONJUR_NAMESPACE=conjur-oss
    HELM_RELEASE=conjur-oss

    pod_name=$(kubectl get pods \
          -n "$CONJUR_NAMESPACE" \
          -l "app=conjur-oss-postgres,release=$HELM_RELEASE" \
          -o jsonpath="{.items[0].metadata.name}")
    kubectl logs -n "$CONJUR_NAMESPACE" "$pod_name" conjur-oss-nginx
    ```

  </details>

### Step-by-Step: Verifying Your Conjur Authentication Configuration

Follow the steps below to perform a systematic, step-by-step evaluation
of your Conjur authentication configuration.

1. Checking the running state of the Conjur deployment.

   <details>
     <summary>Click to see how to check the running state of the Conjur deployment.</summary>

     Check the state of the Conjur deployment as follows:

     ```sh-session
         $ kubectl get pods -n conjur-oss -l release=conjur-oss
         NAME                          READY   STATUS    RESTARTS   AGE
         conjur-oss-5cb86bf558-vrr4r   2/2     Running   0          26m
         conjur-oss-postgres-0         1/1     Running   0          26m
         $
     ```
   </details>

   If the Conjur server pod and the Postgres backend pod are not in the
   `Running` state, or their containers are not ready (2/2 for the
   server and 1/1 for the Postgresql pod), then:

   - Check the [Conjur server logs](#collecting-conjur-server-logs)
     for warnings or errors.
   - Check the [Postgres pod logs](#collecting-conjur-postgres-pod-logs)
     for warnings or errors.
   - [Enable Conjur debug logging](#enabling-debug-logs-for-the-conjur-server),
     and then delete the Conjur Open Source server pod to force a pod recreate, and
     check the [Conjur server logs](#collecting-conjur-server-logs) again
     for warnings or errors.

1. Check that the Conjur server is up and running.

   <details>
     <summary>Click to see how to check that the Conjur server is up.</summary>

     The easiest way to check Conjur status is to run a Helm test.
     The Conjur server is up if a Helm test reports a `Succeeded` phase:

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     $ CONJUR_NAMESPACE=conjur-oss
     $ HELM_RELEASE=conjur-oss

     $ helm test -n "$CONJUR_NAMESPACE" "$HELM_RELEASE" | grep "Phase:"
     Phase:          Succeeded
     $
     ```
   </details>

   If the Conjur server check fails, check the
   [Conjur server logs](#collecting-conjur-server-logs) for warnings or errors.

1. Verify that the Conjur Kubernetes Authenticator plugin is enabled
   in Conjur.

   <details>
     <summary>Click to see how to check that the Kubernetes Authenticator is enabled.</summary>

     The list of enabled Conjur authenticators can be read from the
     Conjur authenticators secret. Here is an example of how to
     read the enabled authenticators from this secret:

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     $ CONJUR_NAMESPACE=conjur-oss
     $ HELM_RELEASE=conjur-oss

     $ authenticators="$(kubectl get secret \
               -n "$CONJUR_NAMESPACE" \
               "$HELM_RELEASE-conjur-authenticators" \
               --template={{.data.key}} \
               | base64 -d \
               | sed 's/,/\n  /g')"
     $ echo "Enabled Conjur authenticators:"; echo "  $authenticators"
     Enabled Conjur authenticators:
       authn
       authn-k8s/my-authenticator-id
     $
     ```
     
     In the above example, there are two Conjur authenticators that are enabled:

     - authn:  The default Conjur authenticator
     - authn-k8s/my-authenticator-id: The Conjur Kubernetes authenticator
               with an authenticator ID of `my-authenticator-id`.
   </details>

     If you do not see the Conjur Kubernetes Authenticator (`authn-k8s`)
     enabled, you can enable it with Helm upgrade.

   <details>
     <summary>Click to see how to enable the Kubernetes Authenticator with Helm upgrade.</summary>

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     $ CONJUR_NAMESPACE=conjur-oss
     $ HELM_RELEASE=conjur-oss
     $ AUTHENTICATOR_ID="my-authenticator-id"

     $ helm upgrade \
         -n "$CONJUR_NAMESPACE" \
         --reuse-values \
         --set authenticators="authn\,authn-k8s/$AUTHENTICATOR_ID" \
         --wait \
         --timeout 300s \
         "$HELM_RELEASE" \
         ./conjur-oss
      ```
   </details>

1. Verify that a Conjur Authentication `ClusterRole` exists.

   <details>
     <summary>Click to see how to check for an authentication `ClusterRole`.</summary>

     For example:

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     $ CONJUR_NAMESPACE=conjur-oss
     $ HELM_RELEASE=conjur-oss

     $ kubectl get clusterrole -n "$CONJUR_NAMESPACE" -l app=conjur-oss -o name
     clusterrole.rbac.authorization.k8s.io/conjur-oss-conjur-authenticator
     $
     ```
   </details>

   If you don't see a Conjur authentication `ClusterRole`, make sure that
   the chart value for `rbac.create` is set to true.

   <details>
     <summary>Click to see how to check the current value of `rbac.create`.</summary>

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     CONJUR_NAMESPACE=conjur-oss
     HELM_RELEASE=conjur-oss

     helm get values --all -n "$CONJUR_NAMESPACE" "$HELM_RELEASE"
     ```
   <details>

1. Verify that either a `ClusterRoleBinding` or `RoleBinding` has been
   created for Conjur authentication.

   *_NOTE: Using a `RoleBinding` is preferred over using a
   `ClusterRoleBinding` for Conjur authentication since `RoleBindings`
   limit the scope of permissions granted to the Kubernetes `Namespace`
   in which it exists._*

   <details>
     <summary>Click to see how to check for a `ClusterRoleBinding`.</summary>

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     HELM_RELEASE=conjur-oss

     crb="$(kubectl get clusterrolebinding | grep ClusterRole\/$HELM_RELEASE-conjur-authenticator | awk '{print $1}')"
     if [ -z "$crb" ]; then
       echo "No ClusterRoleBinding found for Conjur authentication!"
     else
       cluster_role="$(kubectl get clusterrolebinding $crb -o jsonpath='{.roleRef.name}')"
       subjects="$(kubectl get clusterrolebinding $crb -o jsonpath='{.subjects}')"
       echo "Found ClusterRoleBinding: $crb"
       echo "   It is bound to ClusterRole: $cluster_role"
       echo "   It applies to subjects:     $subjects"
     fi
     ```

     There is a properly configure `ClusterRoleBinding` if the above commands
     find a `ClusterRoleBinding`, and both of the following are true:

     - It is bound to the `ClusterRole` found in the previous step, and...
     - It applies to the Conjur `ServiceAccount` named `conjur-oss`

     Here is a sample successful output:

     ```sh-session
     Found ClusterRoleBinding: conjur-oss-conjur-authenticator
        It is bound to ClusterRole: conjur-oss-conjur-authenticator
        It applies to subjects:     [map[kind:ServiceAccount name:conjur-oss namespace:conjur-oss]]
     ```
   </details>

   <details>
     <summary>Click to see how to check for a `RoleBinding` in the application namespace.</summary>

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     APP_NAMESPACE=app-test
     HELM_RELEASE=conjur-oss

     rb="$(kubectl get rolebinding -n $APP_NAMESPACE | grep ClusterRole\/$HELM_RELEASE-conjur-authenticator | awk '{print $1}')"
     if [ -z "$rb" ]; then
       echo "No RoleBinding found in namespace $APP_NAMESPACE for Conjur authentication!"
     else
       cluster_role="$(kubectl get rolebinding -n $APP_NAMESPACE $rb -o jsonpath='{.roleRef.name}')"
       subjects="$(kubectl get rolebinding -n $APP_NAMESPACE $rb -o jsonpath='{.subjects}')"
       echo "Found RoleBinding: $crb"
       echo "   It is bound to ClusterRole: $cluster_role"
       echo "   It applies to subjects:     $subjects"
     fi
     ```

     There is a properly configure `RoleBinding` if the above commands
     find a `RoleBinding`, and both of the following are true:

     - It is bound to the `ClusterRole` found in the previous step, and...
     - It applies to the Conjur `ServiceAccount` named `conjur-oss`

     Here is a sample successful output:

     ```sh-session
     Found RoleBinding: conjur-oss-conjur-authenticator
        It is bound to ClusterRole: conjur-oss-conjur-authenticator
        It applies to subjects:     [map[kind:ServiceAccount name:conjur-oss namespace:conjur-oss]]
     ```
   </details>

   If neither a `ClusterRoleBinding` nor a `RoleBinding` has been created
   for Kubernetes authentication, expand the text block below to see an
   example of how to create a `RoleBinding` for Kubernetes authentication.

   <details>
     <summary>Click to see how to create a Conjur authentication `RoleBinding`.</summary>

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     APP_NAMESPACE=app-test
     CONJUR_NAMESPACE=conjur-oss
     HELM_RELEASE=conjur-oss

     cat <<EOF | kubectl apply -f -
     apiVersion: rbac.authorization.k8s.io/v1
     kind: RoleBinding
     metadata:
       name: conjur-authenticator-role-binding
       namespace: $APP_NAMESPACE
     subjects:
       - kind: ServiceAccount
         name: conjur-oss
         namespace: $CONJUR_NAMESPACE
     roleRef:
       apiGroup: rbac.authorization.k8s.io
       kind: ClusterRole
       name: $HELM_RELEASE-conjur-authenticator
     EOF
     ```
   </details>

1. Check the authenticator container's Conjur SSL CA certificate.

   The Conjur authenticator container (whether it's Secretless Broker sidecar,
   Kubernetes Authenticator sidecar, or Kubernetes Authenticator init
   container) that is included in your application pod needs to be configured
   with Conjur's CA certificate in order to connect with Conur.

   <details>
     <summary>Click to see how to check the authenticator container's Conjur CA cert.</summary>

     To display the authenticator's Conjur CA certificate:

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     APP_NAMESPACE="app-test"
     APP_POD_LABEL="app=test-app-secretless"
     AUTHN_CONTAINER="secretless"

     APP_POD_NAME="$(kubectl get pod \
                     -n $APP_NAMESPACE \
                     -l $APP_POD_LABEL \
                     -o jsonpath='{.items[0].metadata.name}')"
     kubectl exec \
             -n $APP_NAMESPACE \
             $APP_POD_NAME \
             -c $AUTHN_CONTAINER \
             -- printenv CONJUR_SSL_CERTIFICATE
     ```

     This should be compared with the **actual** Conjur CA certificate,
     which can be read from the Conjur server's NGINX container:

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     CONJUR_NAMESPACE=conjur-oss
     HELM_RELEASE=conjur-oss
     
     CONJUR_POD="$(kubectl get pods -n $CONJUR_NAMESPACE -l app=conjur-oss \
                   -o jsonpath='{.items[0].metadata.name}')"
     kubectl exec -n "$CONJUR_NAMESPACE" "$CONJUR_POD" -c conjur-oss-nginx \
                   -- cat /opt/conjur/etc/ssl/cert/tls.crt
     ```
   </details>

1. Check the Kubernetes authenticator container's `CONJUR_ACCOUNT` setting.

   <details>
     <summary>Click to see how to read the authn container's `CONJUR_ACCOUNT` setting.</summary>

     To display the Conjur account configured for the application's
     authenticator container:

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     APP_NAMESPACE="app-test"
     APP_POD_LABEL="app=test-app-secretless"
     AUTHN_CONTAINER="secretless"

     APP_POD_NAME="$(kubectl get pod \
                     -n $APP_NAMESPACE \
                     -l $APP_POD_LABEL \
                     -o jsonpath='{.items[0].metadata.name}')"
     kubectl exec \
             -n $APP_NAMESPACE \
             $APP_POD_NAME \
             -c $AUTHN_CONTAINER \
             -- printenv CONJUR_ACCOUNT
     ```
   </details>

   The Kubernetes authenticator container's `CONJUR_ACCOUNT` setting shouldmatch the Conjur
   account with which the Conjur server was initialized.

   <details>
     <summary>Click to see how to read the Conjur server's account.</summary>

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     CONJUR_NAMESPACE=conjur-oss

     CONJUR_POD="$(kubectl get pods -n $CONJUR_NAMESPACE -l app=conjur-oss \
                   -o jsonpath='{.items[0].metadata.name}')"
     kubectl exec -n "$CONJUR_NAMESPACE" "$CONJUR_POD" -c conjur-oss \
                   -- printenv CONJUR_ACCOUNT
     ```
   </details>

1. Check the authenticator container's `CONJUR_APPLIANCE_URL` setting.

   The Conjur authenticator container (whether it's Secretless Broker sidecar,
   Kubernetes Authenticator sidecar, or Kubernetes Authenticator init
   container) that is included in your application pod needs to be configured
   with the correct `CONJUR_APPLIANCE_URL` environment setting in order
   to be able to connect with Conjur.

   <details>
     <summary>Click to see how to read the authn container's `CONJUR_APPLIANCE_URL` setting.</summary>

     To display the `CONJUR_APPLIANCE_URL` configured for the application's
     authenticator container:

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     APP_NAMESPACE="app-test"
     APP_POD_LABEL="app=test-app-secretless"
     AUTHN_CONTAINER="secretless"

     APP_POD_NAME="$(kubectl get pod \
                     -n $APP_NAMESPACE \
                     -l $APP_POD_LABEL \
                     -o jsonpath='{.items[0].metadata.name}')"
     CONJUR_APPLIANCE_URL="$(kubectl exec \
             -n $APP_NAMESPACE \
             $APP_POD_NAME \
             -c $AUTHN_CONTAINER \
             -- printenv CONJUR_APPLIANCE_URL)"
     echo "CONJUR_APPLIANCE_URL: $CONJUR_APPLIANCE_URL"
     ```
   </details>

   Confirm that the `CONJUR_APPLIANCE_URL` is correct by curling the
   Conjur server.

   <details>
     <summary>Click to see how to curl the Conjur server using `CONJUR_APPLIANCE_URL`.</summary>

     The CONJUR_APPLIANCE_URL setting can be either:
     
     - A Kubernetes cluster internal address. This will be of the form:

       ```
           https://<Conjur-service-name>.<Conjur-namespace>.svc.cluster.local
       ```

     - An address that is accessible from outside of the Kubernetes cluster. 

     To test an internal (intra-cluster) Conjur address:

     - Create a `pod-curl` pod along with a `pod-curl` command alias
       as decribed in the 
       [Creating a Pod for Curling From Inside the Cluster](#creating-a-pod-for-curling-from-inside-the-cluster]
       section above.
     - Curl the Conjur URL using the `pod-curl` alias, e.g.:

       ```sh-session
       $ pod-curl -s "$CONJUR_APPLIANCE_URL" | grep "Conjur server"
           <p class="font-large">Your Conjur server is running!</p>
       $
       ```

     To test an external Conjur address, use `curl` directly:

     ```sh-session
     curl -s "$CONJUR_APPLIANCE_URL" | grep "Conjur server"
     ```
   </details>

1. Check the authenticator container's `CONJUR_AUTHN_URL` setting.

   The authenticator container uses the URL contained in its
   `CONJUR_AUTHN_URL` environment when authenticating itself
   (i.e. logging in) to Conjur.

   <details>
     <summary>Click to see how to read the authn container's `CONJUR_AUTHN_URL` setting.</summary>

     To display the `CONJUR_AUTHN_URL` configured for the application's
     authenticator container:

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     APP_NAMESPACE="app-test"
     APP_POD_LABEL="app=test-app-secretless"
     AUTHN_CONTAINER="secretless"

     APP_POD_NAME="$(kubectl get pod \
                     -n $APP_NAMESPACE \
                     -l $APP_POD_LABEL \
                     -o jsonpath='{.items[0].metadata.name}')"
     CONJUR_AUTHN_URL="$(kubectl exec \
             -n $APP_NAMESPACE \
             $APP_POD_NAME \
             -c $AUTHN_CONTAINER \
             -- printenv CONJUR_AUTHN_URL)"
     echo "CONJUR_AUTHN_URL: $CONJUR_AUTHN_URL"
     ```
   </details>

   If correctly configured, this should be of the form:

   ```
       https://<CONJUR_APPLIANCE_URL>/authn-k8s/<AUTHENTICATOR-ID>
   ```

   Where:
   - <CONJUR_APPLIANCE_URL> should match the value of
     the `CONJUR_APPLIANCE_URL` environment variable that was retrieved in
     the Step 8.
   - <AUTHENTICATOR-ID> should match the authenticator ID that was
     read from the Conjur authenticators secret in Step 3.

1. Check the authenticator container's `CONJUR_AUTHN_LOGIN` setting.

   The authenticator container's `CONJUR_AUTHN_LOGIN` environment setting
   configures the Conjur host that the authenticator container uses
   to authenticate the application with Conjur.

   <details>
     <summary>Click to see how to read the authn container's `CONJUR_AUTHN_LOGIN` setting.</summary>

     To display the `CONJUR_AUTHN_LOGIN` configured for the application's
     authenticator container:

     ```sh-session
     # Set environment. Modify as necessary to match your setup.
     APP_NAMESPACE="app-test"
     APP_POD_LABEL="app=test-app-secretless"
     AUTHN_CONTAINER="secretless"

     APP_POD_NAME="$(kubectl get pod \
                     -n $APP_NAMESPACE \
                     -l $APP_POD_LABEL \
                     -o jsonpath='{.items[0].metadata.name}')"
     CONJUR_AUTHN_LOGIN="$(kubectl exec \
             -n $APP_NAMESPACE \
             $APP_POD_NAME \
             -c $AUTHN_CONTAINER \
             -- printenv CONJUR_AUTHN_LOGIN)"
     echo "CONJUR_AUTHN_LOGIN: $CONJUR_AUTHN_LOGIN"
     ```
   </details>

   If correctly configured, this should be of the form:

   ```
       host/conjur/authn-k8s/<AUTHENTICATOR-ID/<APP-LAYER>/<APPLICATION-NAME
   ```

   Where:
   - <AUTHENTICATOR-ID> should match the authenticator ID that was
     read from the Conjur authenticators secret in Step 3.
   - <APP-LAYER> is a Conjur layer, which is a group of entities for granting permissions
   - <APPLICATION-NAME> is a string to uniquely identify this application

   Here is an example:

   ```
       host/conjur/authn-k8s/my-authenticator-id/apps/test-app-secretless
   ```

1. Confirm that Conjur policy is configured with the proper Application Identity

   The [Conjur Kubernetes Authenticator (authn-k8s)](https://docs.conjur.org/Latest/en/Content/Operations/Services/k8s_auth.htm)
   plugin that is running on the Conjur server makes use of several forms of
   [Conjur application identity](https://docs.conjur.org/Latest/en/Content/Integrations/Kubernetes_AppIdentity.htm?TocPath=Integrations%7COpenShift%252C%20Kubernetes%252C%20and%20GKE%7C_____2)
   to positively identify the application. Typically, the application
   identities that are used include the following:

   - Application's `Namespace` name
   - Application's `ServiceAccount` name
   - Application's `Deployment` name
   - Application's Authenticator (sidecar or init) container name

   If all of the above resource names match what has been specified in Conjur
   policy, then the application is permitted to access secrets as dictated
   by that policy.

   <details>
     <summary>Click to see how to read Application Identity annotations in Conjur Policy.</summary>

     If you performed the checks in the previous step (Step 10),
     then you should have a `CONJUR_AUTHN_LOGIN` environment variable
     that is set to something like this:

     ```
       host/conjur/authn-k8s/<AUTHENTICATOR-ID/<APP-LAYER>/<APPLICATION-NAME
     ```

     The Conjur host resource that corresponds to this `CONJUR_AUTHN_LOGIN`
     should looks something like this:

     ```
         <CONJUR-ACCOUNT>:host:conjur/authn-k8s/<AUTHENTICATOR-ID/<APP-LAYER>/<APPLICATION-NAME
     ```

     So based on the `CONJUR_AUTHN_LOGIN`, we can display the corresponding
     Conjur host defined in authentication policy:

     ```sh-session
     # Set CONJUR_ACCOUNT according to what was retrieved in Step 7 above.
     CONJUR_ACCOUNT="myConjurAccount"

     HOST_RESOURCE="$CONJUR_ACCOUNT:$(echo $CONJUR_AUTHN_LOGIN | sed 's/\//:/')"
     conjur show $HOST_RESOURCE
     ```
   </details>

   The output from the commands in the expandable text block above should
   show a Conjur host definition that looks similar to the following.

   <details>
     <summary>Click to see example Conjur authentication host definition.</summary>

     ```
     $ conjur show $HOST_RESOURCE
     {
       "created_at": "2020-11-05T20:43:20.039+00:00",
       "id": "myConjurAccount:host:conjur/authn-k8s/my-authenticator-id/apps/test-app-secretless",
       "owner": "myConjurAccount:policy:conjur/authn-k8s/my-authenticator-id/apps",
       "policy": "myConjurAccount:policy:root",
       "permissions": [

       ],
       "annotations": [
         {
           "name": "authn-k8s/namespace",
           "value": "app-test",
           "policy": "myConjurAccount:policy:root"
         },
         {
           "name": "authn-k8s/service-account",
           "value": "test-app-secretless",
           "policy": "myConjurAccount:policy:root"
         },
         {
           "name": "authn-k8s/deployment",
           "value": "test-app-secretless",
           "policy": "myConjurAccount:policy:root"
         },
         {
           "name": "authn-k8s/authentication-container-name",
           "value": "secretless",
           "policy": "myConjurAccount:policy:root"
         },
         {
           "name": "kubernetes",
           "value": "true",
           "policy": "myConjurAccount:policy:root"
         }
       ],
       "restricted_to": [

       ]
     }
     ```
   </details>

   Based on the output from the commands in the expandable text blocks
   above, you should confirm that the `value` fields in the annotations
   array match the application's:

   - `Namespace` name
   - `ServiceAccount` name
   - `Deployment` name
   - Authentication container name

   respectively.

   If any of these annotation values do not match the corresponding
   Kubernetes resource name, then check the Conjur authentication policy
   that you loaded for this application, make corrections, and reload
   the policy.

1. Check that a Conjur Webserver is configured for authenticating the application.

   <details>
     <summary>Click to see how to read Webserver configuration in Conjur.</summary>

     Using the `AUTHENTICATOR-ID` that was read in Step 3, we can find
     all Conjur Webservers that have been created for this authenticator ID,
     e.g.:
     
     ```sh-session
     $ conjur list -k webservice -s $AUTHENTICATOR_ID
     [
       "myConjurAccount:webservice:conjur/authn-k8s/my-authenticator-id"
     ]
     $
     ```

     We can now look at permissions that are associated with that
     Webserver resource. For example:

     ```sh-session
     $ conjur show myConjurAccount:webservice:conjur/authn-k8s/my-authenticator-id
     {
       "created_at": "2020-11-05T20:43:20.884+00:00",
       "id": "myConjurAccount:webservice:conjur/authn-k8s/my-authenticator-id",
       "owner": "myConjurAccount:policy:conjur/authn-k8s/my-authenticator-id",
       "policy": "myConjurAccount:policy:root",
       "permissions": [
         {
           "privilege": "read",
           "role": "myConjurAccount:layer:conjur/authn-k8s/my-authenticator-id/users",
           "policy": "myConjurAccount:policy:root"
         },
         {
           "privilege": "authenticate",
           "role": "myConjurAccount:layer:conjur/authn-k8s/my-authenticator-id/users",
           "policy": "myConjurAccount:policy:root"
         }
       ],
       "annotations": [
         {
           "name": "description",
           "value": "authn service for cluster",
           "policy": "myConjurAccount:policy:root"
         }
       ]
     }
     $
     ```
   </details>

   The Webserver resource should have `read` and `authenticate`
   privileges for users associated with the authenticator ID.

   If this is not the case, then check the Conjur authentication policy
   that you loaded for this application, make corrections, and reload
   the policy.

### Some Useful Conjur Commands

  ```
  # Example: List all hosts associated with a Kubernetes authenticator ID
  conjur list -k host -s my-authenticator-id

  # Example: Show a host definition
  conjur show myConjurAccount:host:conjur/authn-k8s/my-authenticator-id/apps/test-app-secretless

  # Example: Show members of a layer
  conjur role members  myConjurAccount:layer:conjur/authn-k8s/my-authenticator-id/apps

  # Example: List Webservices associated with a Kubernetes authenticator ID, with details
  conjur list -k webservice -s my-authenticator-id --inspect
  ```

### Failure Conditions and How to Troubleshoot

#### Conjur server cannot access application Kubernetes Resources

##### Symptoms

- Authenticator container logs show a CAKC029E or CAKC029 error:

  ```
  ERROR: 2020/10/28 19:30:30 authenticator.go:133: CAKC029E Received invalid response to certificate signing request. Reason: status code 401, 
  ```

- Conjur server logs (with debug logging enabled) show
  `cannot get resource "pods" in API group` error:

  ```
  [origin=127.0.0.1] [request_id=21acd925-d8e5-4d4d-bbd9-12d54cab1202] [tid=51] Authentication Error: #<Kubeclient::HttpError: HTTP status code 403, pods "test-app-summon-sidecar-7c45f76f6c-krzsb" is forbidden: User "system:serviceaccount:conjur-oss:conjur-oss" cannot get resource "pods" in API group "" in the namespace "app-test" for GET https://10.96.0.1/api/v1/namespaces/app-test/pods/test-app-summon-sidecar-7c45f76f6c-krzsb>
  ```

##### Known Causes

- Kubernetes RBAC (`ClusterRole`, `ClusterRoleBinding`, `RoleBinding`) is not
  configured properly for Kubernetes authentication.

- `ServiceAccount` name that is specified in the `ClusterRoleBinding` or
  `RoleBinding` for Kubernetes authentication does not match the Kubernetes
  `ServiceAccount` that the Conjur server pod is using.

##### Resolution

- Do a Helm upgrade to set the `rbac.create` Helm chart value to `true`.
- Create a `RoleBinding` (preferred) for Kubernetes authentication
  (see Step 5 above).
- Modify the `ServiceAccount` name that is specified in the authentication
  `ClusterRoleBinding` or `RoleBinding` so that it matches the name of the
  `ServiceAccount` that the Conjur server pod is using.

#### Conjur Kubernetes Authenticator is not enabled

##### Symptoms

- Authenticator container logs show a `CAKC016 Failed to authenticate` error
- Conjur server logs (with debug logging enabled) show
  `CONJ00004E 'authn-k8s/XXX' is not enabled` error

##### Known Causes

The Kubernetes authenticator is not enabled.

##### Resolution

Use Helm upgrade to enable the Conjur Kubernetes authenticator as described
in Step 3 above.

#### Conjur appliance URL is set incorrectly

##### Symptoms

Authenticator container logs show a CAKC028E error, e.g.:

```
ERROR: 2020/10/28 18:04:14 authenticator.go:128: CAKC028E Failed to send https login request or response. Reason: Post https://not-conjur-oss.conjur-oss.svc.cluster.local/authn-k8s/my-authenticator-id/inject_client_cert: dial tcp: lookup not-conjur-oss.conjur-oss.svc.cluster.local: no such host
```

##### Known Causes

The `CONJUR_APPLIANCE_URL` environment variable is set incorrectly in the
the authentication container's manifest.

##### Resolution

Correct the `CONJUR_APPLIANCE_URL` environment variable in the
the authentication container's manifest.

#### Certificate not valid for domain name in Conjur appliance URL

##### Symptoms

Authenticator container logs show a CAKC028 error, e.g.:

```
ERROR: 2020/10/28 17:21:35 authenticator.go:128: CAKC028E Failed to send https login request or response. Reason: Post https://another-conjur-oss.conjur-oss.svc.cluster.local/authn-k8s/my-authenticator-id/inject_client_cert: x509: certificate is valid for conjur.myorg.com, conjur-oss, conjur-oss.conjur-oss, conjur-oss.conjur-oss.svc, conjur-oss.conjur-oss.svc.cluster.local, not another-conjur-oss.conjur-oss.svc.cluster.local
```

##### Known Causes

The URL specified in the `CONJUR_AUTHN_URL` environment variable for the
authentication container is correctly resolved to an IP, so that the container
can connect with Conjur; however, the URL doesn't match any of the subject
alternative names in the Conjur's SSL certificate. This can happen,
for example, if you are directly using an IP to connect with Conjur.

##### Resolution

Modify the `CONJUR_AUTHN_URL` environment variable for the authentication
container so that it matches the Subject alternative names that are
specified in the Conjur servers SSL certificate. Register the
corresponding domain name with DNS if not done already.


#### Invalid Response to Certificate Signing Request

##### Symptoms

- Authentication container logs show
  `CAKC029E Received invalid response to certificate signing request` error.
- Conjur server logs (with debug logging enabled) show `service_account` or
  `deployment` is `not found in namespace`. For example:

  ```
  [origin=127.0.0.1] [request_id=bdca411b-c43b-4518-a1fc-5066dc277758] [tid=39] Authentication Error: #<Errors::Authentication::AuthnK8s::K8sResourceNotFound: CONJ00026E Kubernetes service_account test-app-secretless not found in namespace app-test>
  ```

##### Known Causes

The Conjur policy that was used to configure application identity does
not use the correct values for the application's `ServiceAccount` name
or `Deployment` name. (See Step 7 above for how to check this).

##### Resolution

The Conjur policy should be corrected so that it contains the proper
application identity (e.g. the application's `Namespace`, `ServiceAccount`, 
`Deployment`, and authentication container name), and reloaded into Conjur.
