---
title: Tutorial - Kubernetes
layout: page
---

{% include toc.md key='introduction' %}

Kubernetes secrets are insecure, for the following reasons:

* They are stored in plaintext at rest in the Kubernetes data store (etcd).
* There is no segmentation of access to secrets by users, groups, pods or containers.
* Access to secrets is not audited.
* Kubernetes does not provide a workflow for handling the lifecycle of these secrets that works for security, developers, and operations personnel.

{% include toc.md key='prerequisites' %}

### Kubernetes

To perform this tutorial, you'll need Kubernetes. The easiest way to get Kubernetes to install [Minikube](https://github.com/kubernetes/minikube/).

### Conjur Server Image

Once you have Minikube, you need to provide the `conjurinc/possum` Docker image to it. The easiest way to do this is to build it locally from source code into Minikube’s Docker.

* Select Minikube as your Docker engine

{% highlight shell %}
$ eval $(minikube docker-env)
{% endhighlight %}

* Clone the Conjur server source code:

{% highlight shell %}
$ git clone git@github.com:conjurinc/possum.git
Cloning into 'possum'...
remote: Counting objects: 445, done.
remote: Compressing objects: 100% (413/413), done.
remote: Total 445 (delta 15), reused 250 (delta 11), pack-reused 0
Receiving objects: 100% (445/445), 376.52 KiB | 0 bytes/s, done.
Resolving deltas: 100% (15/15), done.
Checking connectivity... done.
$ cd possum
{% endhighlight %}

* Build Conjur

Make sure you are in the "possum" directory. Then run the build script:

{% highlight shell %}
$ ./build.sh
{% endhighlight %}

{% include toc.md key='setup' %}

Once you have Minikube running with the Conjur Docker image available to it, you need to run the Conjur server in Kubernetes.

You'll do this by creating three Kubernetes applications:

* `pg` A Postgres database.
* `conjur` The Conjur server, which uses Postgres as the data store.
* `client` The Conjur CLI, which is configured to connect to the Conjur server.

### Postgres

First, create this file as `pg.yaml`:

{% highlight yaml %}
# pg.yaml
---
apiVersion: v1
kind: Service
metadata:
  name: pg
spec:
  ports:
  - port: 5432
  selector:
    app: pg
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: pg
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: pg
    spec:
      containers:
      - image: postgres:9.4
        name: pg
        imagePullPolicy: IfNotPresent
{% endhighlight %}

Then create the `pg` deployment in Kubernetes:

{% highlight shell %}
$ kubectl create -f pg.yaml
service "pg" created
deployment "pg" created
{% endhighlight %}

### Conjur Server

Before you can run the Conjur server, you need to generate a data encryption key. Run the following commands in your shell:

{% highlight shell %}
$ data_key=$(docker run --rm conjurinc/possum data-key generate)
$ echo $data_key
C5eQFJcSh34dLW51w/VDmeMOS5y9fl0P2ShjS+JVRSI=
{% endhighlight %}

For tutorial purposes, we'll simply provide the data key to the Conjur server as a hard-coded environment variable. Hard-coding secrets in the environment is obviously a problem we are trying to solve, not create. We are doing it here because:

1. It's simple, and tutorials are meant to demonstrate the basics rather than explore every detail of a solution.
1. It's a reminder to replace this insecure setup in production scenarios.

We'll cover security hardening at the end of this tutorial.

Create this file as `conjur.yaml`, replacing the `POSSUM_DATA_KEY` variable with the one you just created:

{% highlight yaml %}
# conjur.yaml
---
apiVersion: v1
kind: Service
metadata:
  name: conjur
spec:
  ports:
  - port: 80
    name: http
  selector:
    app: conjur
---
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: conjur
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: conjur
    spec:
      containers:
      - image: conjurinc/possum
        imagePullPolicy: IfNotPresent
        name: conjur
        args: [ server ]
        env:
        - name: DATABASE_URL
          value: postgres://postgres@pg/postgres
        - name: POSSUM_DATA_KEY
          value: C5eQFJcSh34dLW51w/VDmeMOS5y9fl0P2ShjS+JVRSI=
          
      - image: lachlanevenson/k8s-kubectl
        imagePullPolicy: IfNotPresent
        name: kubectl
        command: [ kubectl, proxy, "-p", "8080" ]
{% endhighlight %}

Now create the `conjur` deployment in Kubernetes:

{% highlight shell %}
$ kubectl create -f conjur.yaml
service "conjur" created
deployment "conjur" created
{% endhighlight %}

Listing all Pods, you should see something like this:

{% highlight shell %}
$ kubectl get pods
NAME                      READY     STATUS    RESTARTS   AGE
conjur-1287799974-tlpnl   2/2       Running   0          5m
pg-1051715919-2d1l7       1/1       Running   0          5m
{% endhighlight %}

Save the name of the `conjur` pod in a shell variable:

{% highlight shell %}
$ conjur_pod=$(kubectl get pods | grep conjur | cut -d' ' -f1-1)
$ echo $conjur_pod
conjur-1287799974-tlpnl
{% endhighlight %}

Now enter the Conjur container...

{% highlight shell %}
$ kubectl exec -it $conjur_pod bash
{% endhighlight %}

... and create the account "mycorp":

{% highlight shell %}
$ possum account create mycorp
Created new account account 'mycorp'
Token-Signing Public Key: -----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3KH53gBcpwEzMlkbVMGc
mCStUzGfSZH3ZOXMP1A9gfCGKEqj/LsrdYozNKj4uVIfQoGABSa3m8lxXiXelZQp
3VZiv3kHifuYCrfeL1ahg4j6wNJlxWl/cOONjfrkIuw8Nh/YOlNEmOuIeiol9fFG
drzQgnpRiJnyy4uY65QkJCXRv65NXe1sJkC23I2xrhjSo1uny6wSf5Q4pLGIywye
RBYJ8AtvZ7ibEwAotYFJhFh6InjU/FejS7AojRDmu24Tj1Uo7xqKhEt5GZBcwLg/
F9Rfk2RisS+NYeX62luMXxzJOexnMmdrGWMlxhiib8/0xbbcnTNkcDTa/n7m9h3v
DwIDAQAB
-----END PUBLIC KEY-----
Admin API Key: 3b8k8dn2h2tbb92k07ftvsbkvtx3t4rvyx1v32r0j2bgc8kr1s5afq4
{% endhighlight %}

Save the API key printed above, you'll need it soon.

### Conjur Client

To manage Conjur, we'll create a Pod which has the Conjur CLI available.

Create "client.yaml"

{% highlight yaml %}
---
apiVersion: v1
kind: Pod
metadata:
  name: client
spec:
  containers:
  - image: conjurinc/cli5
    name: cli5
    imagePullPolicy: IfNotPresent
    command: [ sleep ]
    args: [ infinity ]
    env:
    - name: CONJUR_APPLIANCE_URL
      value: http://conjur
    - name: CONJUR_ACCOUNT
      value: mycorp
{% endhighlight %}

And load it:

{% highlight shell %}
$ kubectl create -f client.yaml
pod "client" created
{% endhighlight %}

Now enter the client container...

{% highlight shell %}
$ kubectl exec -it client bash
{% endhighlight %}

And login using the "admin" API Key that was printed earlier:

{% highlight shell %}
$ conjur authn login admin
Please enter admin's password (it will not be echoed):
Logged in
{% endhighlight %}

OK! Initial setup is completed.

{% include toc.md key='policies' %}

With the services are running and configured, we can explore how to setup the Conjur policies so that Kubernetes applications can be managed in a secure and scalable way.

In this section, we will consider three different user roles:

* **Conjur admins** The user group which manages the `root` policy in the Conjur system.
* **Application developers** A development team who is creating an application called "myapp". Some of the members of this team are trained in Conjur policy YAML. This team has authority to manage the Conjur security policies for their own applications (but not for others).
* **Database administrators** A team who owns a database. This team is authorized to manage which applications are permitted to connect to the database.
* **Kubernetes administrators** A team who manages the Kubernetes cluster. This team is authorized to whitelist applications to run within Kubernetes, and ensures that applications follow the organization's security standards.

### Root Policy

The first step is for the Conjur admins to load the root policy. The root policy will define the sub-policies that will be used to manage the applications, the databases, and the Kubernetes system.

Create the policy "root.yml":

{% include policy-file.md policy='kubernetes-root' %}

And load it:

{% highlight shell %}
$ conjur policy load root conjur.yml
Loaded policy 'root'
{
  "created_roles": {
  },
  "version": 2
}
{% endhighlight %}

If you now list the policies in the system, you'll see that there are individual policies for the application, the database, and the "default" namespace in Kubernetes:

{% highlight shell %}
$ conjur list -k policy
[
  "mycorp:policy:kubernetes/default",
  "mycorp:policy:kubernetes",
  "mycorp:policy:prod/myapp",
  "mycorp:policy:prod/mydb",
  "mycorp:policy:prod",
  "mycorp:policy:root"
]
{% endhighlight %}

In a production scenario, different user groups could be created and given management authority over these policies. For this tutorial, we will just use the "admin" user for all operations.

### Kubernetes application list

The job of the Kubernetes team is to manage the security policies for applications as they are deployed to Kubernetes. When an application pod starts up, it will reach out to the Conjur service to login and authenticate. The Kubernetes team creates Conjur Host objects for each application. Until the Host object exists, the application can't login. In this way, the Kubernetes team can be the gatekeeper of sensitive applications running in their system.

Create the policy "k8s-default.yml" to enumerate the applications which are allowed to run in the "default" Kubernetes namespace:

{% include policy-file.md policy='kubernetes-k8s-default' %}

Then load it:

{% highlight shell %}
$ conjur policy load kubernetes/default k8s-default.yml
Loaded policy 'kubernetes/default'
{
  "created_roles": {
    ...
  },
  "version": 1
}
{% endhighlight %}

The command prints an API key for the role `mycorp:host:kubernetes/default/deployment/myapp`; however, you can ignore it. In Kubernetes, the applications login to Conjur using their Kubernetes metadata, not using passwords or API keys.

### Application policy

Next, the application team defines the policy for their application. This policy has the typical objects : a layer, some secrets, a permission grant.

It also adds the Kubernetes host to the application layer, so that when the app authenticates in Kubernetes, it will inherit the permissions of the layer.

Create the policy "myapp.yml":

{% include policy-file.md policy='kubernetes-myapp' %}

Then load it:

{% highlight shell %}
$ conjur policy load prod/myapp myapp.yml
Loaded policy 'prod/myapp'
{
  "created_roles": {
  },
  "version": 1
}
{% endhighlight %}

You can now confirm that the Kubernetes host "myapp" is a member of the application layer "myapp":

{% highlight shell %}
$ conjur role memberships host:kubernetes/default/deployment/myapp
[
  "mycorp:layer:prod/myapp",
  "mycorp:host:kubernetes/default/deployment/myapp"
]
{% endhighlight %}

### Database policy

To make this example more realistic, we are simulating the scenario in which "myapp" needs to connect to a database "mydb" which is managed by a different team.

Create the policy "mydb.yml":

{% include policy-file.md policy='kubernetes-database' %}

Then load it:

{% highlight shell %}
$ conjur policy load prod/mydb mydb.yml
Loaded policy 'prod/mydb'
{
  "created_roles": {
  },
  "version": 1
}
{% endhighlight %}

Confirm that the Kubernetes host has "execute" permission on the database password:

{% highlight shell %}
$ conjur resource permitted_roles variable:prod/mydb/password execute
[
  ...
  "mycorp:host:kubernetes/default/deployment/myapp",
  ...
]
{% endhighlight %}

{% include toc.md key='add-secret' %}

Now that the objects and permissions have all been created, we just need to store the database password in Conjur before we run the app.

Use `openssl` to generate a random secret, and store it in the DB password variable:

{% highlight shell %}
$ password=$(openssl rand -hex 12)
$ echo $password
d0b9ffa7c21074034826da71
$ echo $password | conjur variable values add prod/mydb/password
Value added
{% endhighlight %}

{% include toc.md key='app' %}


