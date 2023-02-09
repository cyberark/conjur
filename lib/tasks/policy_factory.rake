# frozen_string_literal: true

require 'base64'

module Factory
  module Templates
    class ValidateTemplate
      def initialize(renderer: Factory::RenderPolicy.new)
        @renderer = renderer
      end

      def test(factory:, template_params:)
        puts('template:')
        puts(factory.policy_template)
        puts('--------------')
        puts('')
        puts('rendered template:')
        puts(@renderer.render(policy_template: factory.policy_template, variables: template_params))

        # puts(ERB.new(@factory.policy_template, nil, '-').result_with_hash(args))
      end
    end
  end
end

namespace :policy_factory do
  def api_key
    return ENV['CONJUR_AUTHN_API_KEY'] if ENV.key?('CONJUR_AUTHN_API_KEY')

    raise 'Conjur `admin` user API key must be provided via `CONJUR_AUTHN_API_KEY` environment variable'
  end

  def client
    @client ||= begin
      Conjur.configuration.account = 'cucumber'
      Conjur.configuration.appliance_url = 'http://localhost:3000/'
      Conjur::API.new_from_key('admin', api_key)
    end
  end

  task test: :environment do
    tester = Factory::Templates::ValidateTemplate.new
    tester.test(
      factory: Factory::Templates::Core::Group,
      template_params: { "id"=>"test-group", "branch"=>"root", "annotations"=>{ "one"=>1, "two"=>2, "test/three"=>3 } }
    )
    tester.test(
      factory: Factory::Templates::Core::Group,
      template_params: { "id"=>"test-group", "branch"=>"root" }
    )
  end

  task load: :environment do
    client.load_policy('root', Factory::Templates::BasePolicy.policy)
    client.resource('cucumber:variable:conjur/factories/core/group').add_value(Factory::Templates::Core::Group.data)
    client.resource('cucumber:variable:conjur/factories/core/managed-policy').add_value(Factory::Templates::Core::ManagedPolicy.data)
    client.resource('cucumber:variable:conjur/factories/core/policy').add_value(Factory::Templates::Core::Policy.data)
    client.resource('cucumber:variable:conjur/factories/core/user').add_value(Factory::Templates::Core::User.data)
    client.resource('cucumber:variable:conjur/factories/authenticators/authn-oidc').add_value(Factory::Templates::Authenticators::AuthnOidc.data)
    client.resource('cucumber:variable:conjur/factories/connections/database').add_value(Factory::Templates::Connections::Database.data)
  end

  task retrieve_auth_token: :environment do
    url = 'http://localhost:3000/'
    username = 'admin'

    response = RestClient.post("#{url}/authn/cucumber/#{username}/authenticate", api_key, 'Accept-Encoding' => 'base64')
    puts response.body
  end
end
