# Regenerating Test Certificates

To regenerate these certificate:

- Clone [conjurdemos/conjur-intro](https://github.com/conjurdemos/conjur-intro)
  repository.
- Go to `tools/simple-certificates` directory.
- Run `./generate_certificates 2 chained`.
- Copy relevant certificates from `certificates/` directory to here and build
  full chain bundle

  ```bash
  cp ./certificates/nodes/chained.mycompany.local/chained.mycompany.local.cert.pem ./
  cp ./certificates/nodes/chained.mycompany.local/chained.mycompany.local.key.pem ./
  cp ./certificates/root/certs/root.cert.pem ./
  cp chained.mycompany.local.cert.pem ca-chain.cert.pem
  cat ./certificates/ca-chain.cert.pem >> ./ca-chain.cert.pem
  ```
