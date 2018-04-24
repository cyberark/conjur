require 'authenticators/security'

RSpec.describe Authentication::Security do

  # generates authorized or unauthorized user roles
  user_role = ->(can_authenticate) do
    double('user_role').tap do |role|
      allow(role).to receive(:allowed_to?).and_return(can_authenticate)
    end
  end

  # generates authorized or unauthorized role classes, ie, 
  # role_class = ->(can_authenticate) do
  #   double('user_role').tap do |role|
  #     allow(role).to receive(:allowed_to?).and_return(can_authenticate)
  #   end
  # end
  authn_type             = 'my-authn-type'
  account                = 'my-account'
  # authorized_user_role   = user_role.(true)
  # unauthorized_user_role = user_role.(false)
  let(:role_class) do
    double('Role',
           :roleid_from_username => 'some-role-id',
           :[] => user_role)
  end

  context "A webservice that is not enabled in Conjur" do

    service_id = 'my-service-id'
    good_service = Authentication::Webservice.new(
      account: account, authn_type: authn_type, service_id: service_id
    )
    avail_services = Authentication::Webservices.new([good_service])
    let(:role_class) { double }
    let(:resource_class) { double }

    it "raises a NotEnabled error" do
      bad_service = Authentication::Webservice.new(
        account: account, authn_type: authn_type, service_id: 'blah'
      )
      subject = Authentication::Security.new(
        role_class: role_class,
        resource_class: resource_class
      )
      access_request = Authentication::RequestForAccess.new(
        webservice: bad_service,
        whitelisted_webservices: avail_services,
        user_id: 'some-user'
      )
      expect { subject.validate(access_request) }.to(
        raise_error(Authentication::NotWhitelisted)
      )
    end
  end

  # context "Incorrect server response format" do
  #   it "reraises an UnexpectedServerResponse" do
  #     expect { Ldap::HttpStatusError.new(unexpected_error) }.to(
  #       raise_error(Ldap::UnexpectedServerResponse)
  #     )
  #   end
  # end

end

__END__

user1:
  can authenticate with ws1
  cannot authenticate with ws2
user2:
  can authenticate with ws2
  cannot authenticate with ws1
