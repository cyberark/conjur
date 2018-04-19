require 'ldap/http_status_error'
require 'ldap/unexpected_server_response'

RSpec.describe Authenticators::Security do

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
  let(:authn_type) { 'my-authn-type' }
  let(:account) { 'my-account' }
  let(:authorized_user_role) { user_role.(true) }
  let(:unauthorized_user_role) { user_role.(false) }
  let(:role_class) do
    double('Role',
           :roleid_from_username => 'some-role-id',
           :[] => user_role)
  end

  context "When the webservice is not enabled in Conjur" do

    it "raises a ServiceNotDefined error" do
      subject = Authenticators::Security.new(
        authn_type: authn_type,
        account: account,
        role_class: Role,
        resource_class: Resource,
        whitelisted_authenticators: ENV['CONJUR_AUTHENTICATORS']
      )
      expect(subject.validate('some-service', 'some-user')).to(
        raise_error(ServiceNotDefined))
    end
  end

  context "Incorrect server response format" do
    it "reraises an UnexpectedServerResponse" do
      expect { Ldap::HttpStatusError.new(unexpected_error) }.to(
        raise_error(Ldap::UnexpectedServerResponse)
      )
    end
  end

end

__END__

user1:
  can authenticate with ws1
  cannot authenticate with ws2
user2:
  can authenticate with ws2
  cannot authenticate with ws1
