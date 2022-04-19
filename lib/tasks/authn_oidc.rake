# require 'app/domain/authentication/authn_oidc_2/authenticator'
require 'app/domain/resource_engine'
require 'securerandom'
namespace :oidc do
  def state
    '8e82d35323913ebc3f9f593e1bcfc579'
  end

  def authenticator
    ::Authentication::AuthnOidc2::Callback.new(
      config: {
        issuer_uri: ENV['OIDC_ISSUER_URI'],
        client_id: ENV['OIDC_CLIENT_ID'],
        client_secret: ENV['OIDC_CLIENT_SECRET'],
        redirect_uri: 'http://localhost:3000/authn-oidc/okta/cucumber/callback',
        claim_mapping: 'preferred_username'
      },
      state: state,
      nonce: '2f9593e21ac9eac028c530d19088f993'
    )
  end

  task redirect_url: :environment do
    puts authenticator.redirect_uri
  end

  task :run, [:code] => :environment do |_, args|
    name = authenticator.call(
      params: {
        code: args.code,
        state: state
      }
    )
    puts "name: #{name}"
  end

  task create: :environment do
    authenticator = Authenticator::Repository::Oidc.new
    authenticator.create(
      authenticator: Authenticator::Repository::Schema::Oidc.new(
        service_id: "test-oidc-#{SecureRandom.hex(3)}",
        provider_uri: ENV['OIDC_ISSUER_URI'],
        client_id: ENV['OIDC_CLIENT_ID'],
        client_secret: ENV['OIDC_CLIENT_SECRET'],
        claim_mapping: 'preferred_username'
      )
    )
  end
  task find: :environment do
    authenticator = Authenticator::Repository::Oidc.new(account: 'cucumber')
    puts authenticator.find(service_id: 'jv-oidc-1')
  end

  task update: :environment do
    authenticator = Authenticator::Repository::Oidc.new(account: 'cucumber')
    authenticator.update(
      authenticator: Authenticator::Repository::Schema::Oidc.new(
        service_id: 'test-oidc-1',
        provider_uri: ENV['OIDC_ISSUER_URI'],
        client_id: ENV['OIDC_CLIENT_ID'],
        client_secret: ENV['OIDC_CLIENT_SECRET'],
        claim_mapping: 'preferred_username'
      )
    )
  end
end
