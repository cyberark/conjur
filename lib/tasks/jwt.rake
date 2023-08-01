require 'rest-client'
require 'jwt'

# This library is useful for generating JWT tokens for testing the authn-jwt Strategy library.

namespace :jwt do
  namespace :generate do
    def generate_jwt(claims, with_defaults: true)
      if with_defaults
        claims = {
          exp: Time.now.to_i + 604800
        }.merge(claims)
      end

      result = RestClient.post(
        'http://jwks_py:8090/authn-jwt-check-standard-claims/RS256',
        JWT.encode(claims, nil, 'none')
      )
      result.body
    end

    desc 'Generates a basic JWT certificate'
    task basic: :environment do
      puts generate_jwt({ host: 'myapp', project_id: 'myproject', iat: Time.now.to_i })
    end

    desc 'Generates a JWT with missing claims'
    task missing_required_claim: :environment do
      puts generate_jwt({ host: 'myapp' }, with_defaults: false)
    end

    desc 'Generates an empty JWT'
    task empty: :environment do
      puts generate_jwt({}, with_defaults: false)
    end

    desc 'Generates an expired JWT'
    task expired: :environment do
      puts generate_jwt({ host: 'myapp', project_id: 'myproject', iat: Time.now.to_i, exp: Time.now.to_i - 604800 })
    end

    desc 'Generates a JWT with additional claims'
    task full: :environment do
      puts generate_jwt({
        host: 'myapp',
        project_id: 'myproject',
        iss: 'Conjur Unit Testing',
        aud: 'rspec',
        iat: Time.now.to_i
      })
    end
  end
end
