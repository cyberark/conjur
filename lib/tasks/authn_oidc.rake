require 'app/domain/authentication/authn_oidc_2/authenticator'

namespace :oidc do
  def state
    '8e82d35323913ebc3f9f593e1bcfc579'
  end

  def authenticator
    ::Authentication::AuthnOidc2::Callback.new(
      config: {
        issuer_uri: 'https://dev-92899796.okta.com/oauth2/default',
        client_id: '0oa3w3xig6rHiu9yT5d7',
        client_secret: 'xUJKcusQXhWrq_ufsxTQBdNKtJHdKCNoyGLrL_Xk',
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
end
