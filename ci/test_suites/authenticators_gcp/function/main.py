import requests

def func_name(request):
    if request.method == 'GET':
        audience = request.args['audience']
        token_response = requests.get(
            f'http://metadata/computeMetadata/v1/instance/service-accounts/default/identity?audience={audience}',
            headers={'Metadata-Flavor': 'Google'},
            timeout=300 # 5 minutes
        )
        return token_response.text

    # Only GET is supported; abort 405 http method not supported
    # Disable the following from Pylint since it is not defined in this scope
    return abort(405) # pylint: disable=undefined-variable
