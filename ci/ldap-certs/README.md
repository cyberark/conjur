# Regenerating Test Certificates
The certs required for DEV/CI environments are automatically generated based on the below steps:

- Clone https://github.com/conjurdemos/conjur-intro repository.
- Go to `tools/simple-certificates` directory.
- Run `./generate_certificates 3 ldap-server`.
- Copy relevant certificates from `certificates/` directory to here. If your
  `conjur-intro` `tools/simple-certificates` directory is located at $CONJUR_INTRO_DIR
  then you can run the following commands from this directory:
  ```
  cp $CONJUR_INTRO_DIR/certificates/ca-chain.cert.pem ./
  cp $CONJUR_INTRO_DIR/certificates/nodes/ldap-server.mycompany.local/ldap-server.mycompany.local.cert.pem ldap-server.cert.pem 
  cp $CONJUR_INTRO_DIR/certificates/nodes/ldap-server.mycompany.local/ldap-server.mycompany.local.key.pem ldap-server.key.pem 
  cp $CONJUR_INTRO_DIR/certificates/root/certs/root.cert.pem ./
  ```
