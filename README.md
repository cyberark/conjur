# Possum

## Development

Create and start the dev environment:

```sh-session
$ docker-compose build
$ docker-compose up -d
```

Enter the application container:

```sh-session
$ docker exec -it possum_app-dev_1 bash
/src/possum # 
```

Optional: configure local bundler

```sh-session
/src/possum # bundle config local.conjur-policy-parser /src/conjur-policy-parser/
```

Bundle

```sh-session
/src/possum # bundle
```

Create the token-signing private key:

```sh-session
/src/possum # ssh-keygen -f ./id_rsa
Generating public/private rsa key pair.
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in ./id_rsa.
Your public key has been saved in ./id_rsa.pub.
The key fingerprint is:
7c:c3:60:d3:2b:c0:0a:ff:0a:2b:9f:f0:02:31:12:11 kgilpin@spudling-2.local
The key's randomart image is:
+--[ RSA 2048]----+
|Eo               |
|.    .   .       |
| ..   o + .      |
|+  o . + + .     |
|.o  o   S =      |
|.    .   o .     |
|o .   .          |
|oo + .           |
| += .            |
+-----------------+
/src/possum # export POSSUM_PRIVATE_KEY="$(cat id_rsa)"
```

Go!

```sh-session
/src/possum # 
/src/possum # ./bin/rails s
```

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...


Please feel free to use a different markup language if you do not plan to run
<tt>rake doc:app</tt>.
