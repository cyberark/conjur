from __future__ import absolute_import

import base64
import os
import pathlib
import unittest

import conjur

from OpenSSL import crypto, SSL

CERT_DIR = pathlib.Path('config/https')
SSL_CERT_FILE = 'ca.crt'
CONJUR_CERT_FILE = 'conjur.crt'
CONJUR_KEY_FILE = 'conjur.key'

def generateKey(type, bits):
    """Generates a key using OpenSSL"""
    key = crypto.PKey()
    key.generate_key(type, bits)

    return key

def generateCSR(host_id, key):
    """Generate a Certificate Signing Request"""
    pod_name = os.environ['MY_POD_NAME']
    namespace = os.environ['TEST_APP_NAMESPACE']
    SANURI = f'spiffe://cluster.local/namespace/{namespace}/podname/{pod_name}'


    req = crypto.X509Req()
    req.get_subject().CN = host_id
    req.set_pubkey(key)

    formatted_SAN = f'URI:{SANURI}'
    req.add_extensions([
        crypto.X509Extension(
            'subjectAltName'.encode('ascii'), False, formatted_SAN.encode('ascii')
        )
    ])

    req.sign(key, "sha1")

    return crypto.dump_certificate_request(crypto.FILETYPE_PEM, req)

class TestClientCertInject(unittest.TestCase):

    def setUp(self):
        with open(os.environ['CONJUR_AUTHN_TOKEN_FILE'], 'r') as content:
            encoded_token = base64.b64encode(content.read().replace('\r', '').encode()).decode('utf-8')

        config = conjur.Configuration(
                host='https://conjur-oss:9443'
            )

        with open(CERT_DIR.joinpath(SSL_CERT_FILE), 'w') as content:
            content.write(os.environ['CONJUR_SSL_CERTIFICATE'])

        config.ssl_ca_cert = CERT_DIR.joinpath(SSL_CERT_FILE)
        config.username = 'admin'
        config.api_key = {'Authorization': 'Token token="{}"'.format(encoded_token)}

        self.client = conjur.ApiClient(config)
        self.api = conjur.api.AuthenticationApi(self.client)

        key = generateKey(crypto.TYPE_RSA, 2048)
        self.csr = generateCSR('app-test/*/*', key)

    def tearDown(self):
        self.client.close()

    def test_inject_202(self):
        """Test 202 status response when successfully requesting a client certificate injection
        202 - successful request and injection
        """
        # optional prefix
        # prefix = 'host/conjur/authn-k8s/my-authenticator-id/apps'
        response, status, _ = self.api.k8s_inject_client_cert_with_http_info(
            'my-authenticator-id',
            body=self.csr
        )

        self.assertEqual(status, 202)
        self.assertEqual(None, response)

    def test_inject_400(self):
        """Test 400 status response when successfully requesting a cert injection
        400 - Bad Request caught by NGINX
        """
        with self.assertRaises(conjur.ApiException) as context:
            self.api.k8s_inject_client_cert(
                '\00',
                body=self.csr
            )

        self.assertEqual(context.exception.status, 400)

    def test_inject_401(self):
        """Test 401 status response when requesting a cert injection
        401 - unauthorized request. This happens from invalid Conjur auth token,
        incorrect service ID, malformed CSR and others
        """
        with self.assertRaises(conjur.ApiException) as context:
            self.api.k8s_inject_client_cert(
                'wrong-service-id',
                body=self.csr
            )

        self.assertEqual(context.exception.status, 401)

    def test_inject_404(self):
        """Test 404 status response when requesting a cert injection
        404 - Resource not found, malformed service ID
        """
        with self.assertRaises(conjur.ApiException) as context:
            self.api.k8s_inject_client_cert(
                '00.00',
                body=self.csr
            )

        self.assertEqual(context.exception.status, 404)

if __name__ == '__main__':
    unittest.main()
