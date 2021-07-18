#!/usr/bin/env python3
'''Lightweight JWKS server'''

import argparse
import base64
import json
import logging
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, HTTPServer
from collections import OrderedDict
from jwcrypto import jwt, jwk

DEFAULT_PORT = 8080
JWKS_KEYS_KEY = 'keys'

keys = {}


def get_key(key_name, alg):
    '''
    Returns key from keys dictionary accoding key_name
    If key_name key does not exist in the keys dictionary creates according alg
    '''
    if key_name not in keys:
        keys[key_name] = {
            'RS256': jwk.JWK.generate(kty='RSA', size=1024),
            'RS384': jwk.JWK.generate(kty='RSA', size=2048),
            'RS512': jwk.JWK.generate(kty='RSA', size=4048),
            'ES256': jwk.JWK.generate(kty='EC', crv='P-256'),
            'ES384': jwk.JWK.generate(kty='EC', crv='P-384'),
            'ES512': jwk.JWK.generate(kty='EC', crv='P-521'),
            'HS256': jwk.JWK.generate(kty='oct', size=256),
            'HS384': jwk.JWK.generate(kty='oct', size=384),
            'HS512': jwk.JWK.generate(kty='oct', size=512)
        }.get(alg, None)
    return keys[key_name]


def export_key_with_kid(key):
    '''Returns key as dictionary with kid'''
    try:
        key_json = key.export(private_key=False)
    except jwk.InvalidJWKType:
        key_json = key.export()
    key_dict = json.loads(key_json, object_pairs_hook=OrderedDict)
    key_dict['kid'] = key.thumbprint()
    return key_dict


def jwks_json_with_single_key(key):
    '''Creates JWKS json with single key'''
    return json.dumps({
        JWKS_KEYS_KEY: [
            export_key_with_kid(key)
        ]
    })


def jwks_json_with_all_keys():
    '''Creates JWKS json with all keys'''
    key_list = []
    for key in keys.values():
        key_list.append(export_key_with_kid(key))
    return json.dumps({
        JWKS_KEYS_KEY: key_list
    })


def base64_padding(value):
    '''Completing base64 '=' padding if needed'''
    return value + "=" * (-len(value) % 4)


def decode_token(token):
    '''Returns header and body part of JWT token as objects'''
    head_b64, payl_b64, sig = token.split(".", 3)
    head = base64.urlsafe_b64decode(base64_padding(head_b64))
    payl = base64.urlsafe_b64decode(base64_padding(payl_b64))
    head_dict = json.loads(head, object_pairs_hook=OrderedDict)
    payl_dict = json.loads(payl, object_pairs_hook=OrderedDict)
    return head_dict, payl_dict


class JWKSRequestHandler(BaseHTTPRequestHandler):
    '''Handles http requests'''

    def reply(self, response):
        '''Returns response to a client'''
        self.send_response(HTTPStatus.OK)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(response.encode('utf-8'))

    def do_GET(self):
        '''Handles GET requests'''
        logging.info("GET: %s", str(self.path))
        parts = self.path.strip('/').split('/')

        if len(parts) == 2:
            resp = jwks_json_with_single_key(
                get_key(parts[0], parts[1])
            )
        else:
            resp = jwks_json_with_all_keys()
        self.reply(resp)

    def do_POST(self):
        '''Handles POST requests'''
        logging.info("POST %s", str(self.path))

        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        logging.info("BODY %s", post_data.decode('utf-8'))

        key_name, alg = self.path.strip('/').split('/')
        key = get_key(key_name, alg)

        head, payl = decode_token(post_data.decode('utf-8'))
        head['alg'] = alg
        head['kid'] = key.thumbprint()

        token = jwt.JWT(header=head, claims=payl)
        token.make_signed_token(key)
        self.reply(token.serialize())

    def do_DELETE(self):
        '''Handles DELETE requests'''
        logging.info("DELETE %s", str(self.path))
        parts = self.path.strip('/').split('/')
        if len(parts) == 2:
            del keys[parts[0]]
        else:
            keys.clear()
        self.reply("DELETED")


def run(port, server_class=HTTPServer, handler_class=JWKSRequestHandler):
    '''Runs http server'''
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    logging.info('Starting JWKS server...')
    logging.info('Port: %d', port)
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    httpd.server_close()
    logging.info('Stopping server...')


logging.basicConfig(level=logging.INFO)
parser = argparse.ArgumentParser(description='Lightweight JWKS server')
parser.add_argument(
    '-p',
    '--port',
    type=int,
    default=DEFAULT_PORT,
    help=f"defines http server port (default: {DEFAULT_PORT})")
args = parser.parse_args()
run(args.port)
