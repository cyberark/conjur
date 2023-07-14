# frozen_string_literal: true

module Factory
  module Templates
    class ValidateTemplate
      def initialize(renderer: Factories::RenderPolicy.new)
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
    binding.pry
    # tester = Factories::Templates::ValidateTemplate.new
    # tester.test(
    #   factory: Factories::Templates::Core::Group,
    #   template_params: { "id"=>"test-group", "branch"=>"root", "annotations"=>{ "one"=>1, "two"=>2, "test/three"=>3 } }
    # )
    # tester.test(
    #   factory: Factories::Templates::Core::Group,
    #   template_params: { "id"=>"test-group", "branch"=>"root" }
    # )
  end

  task load: :environment do
    binding.pry
    client.load_policy('root', Factories::Templates::Base::V1::BasePolicy.policy)
    client.resource('cucumber:variable:conjur/factories/core/v1/group').add_value(Factories::Templates::Core::V1::Group.data)
    client.resource('cucumber:variable:conjur/factories/core/v1/managed-policy').add_value(Factories::Templates::Core::V1::ManagedPolicy.data)
    client.resource('cucumber:variable:conjur/factories/core/v1/policy').add_value(Factories::Templates::Core::V1::Policy.data)
    client.resource('cucumber:variable:conjur/factories/core/v1/user').add_value(Factories::Templates::Core::V1::User.data)
    client.resource('cucumber:variable:conjur/factories/authenticators/v1/authn-oidc').add_value(Factories::Templates::Authenticators::V1::AuthnOidc.data)
    client.resource('cucumber:variable:conjur/factories/connections/v1/database').add_value(Factories::Templates::Connections::V1::Database.data)
  end

  task retrieve_auth_token: :environment do
    url = 'http://localhost:3000/'
    username = 'admin'

    response = RestClient.post("#{url}/authn/cucumber/#{username}/authenticate", api_key, 'Accept-Encoding' => 'base64')
    puts response.body
  end
end
