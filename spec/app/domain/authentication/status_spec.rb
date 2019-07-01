# frozen_string_literal: true

RSpec.describe Authentication::Status do

  ### From ValidateSecurity spec

  let (:test_account) { 'test-account' }
  let (:non_existing_account) { 'non-existing' }

  # generates user_role authorized for all or no services
  def user_role(is_authorized:)
    double('user_role').tap do |role|
      allow(role).to receive(:allowed_to?).and_return(is_authorized)
    end
  end

  def role_class(returned_role)
    double('role_class').tap do |role_class|
      allow(role_class).to receive(:roleid_from_username).and_return('some-role-id')
      allow(role_class).to receive(:[]).and_return(returned_role)

      allow(role_class).to receive(:[])
                             .with(/#{test_account}:user:admin/)
                             .and_return(user_role(is_authorized: true))

      allow(role_class).to receive(:[])
                             .with(/#{non_existing_account}:user:admin/)
                             .and_return(nil)
    end
  end

  def resource_class(returned_resource)
    double('Resource').tap do |resource_class|
      allow(resource_class).to receive(:[]).and_return(returned_resource)
    end
  end

  let (:full_access_role_class) { role_class(user_role(is_authorized: true)) }
  let (:no_access_role_class) { role_class(user_role(is_authorized: false)) }

  let (:full_access_resource_class) { resource_class('some random resource') }
  let (:non_existing_resource_class) { resource_class(nil) }

  ### Only here


  let (:mock_enabled_authenticators) do
    "authn-status-pass,authn-status-not-implemented"
  end

  let (:not_including_enabled_authenticators) do
    "authn-other"
  end

  def authenticator(is_status_defined:, is_failing_requirements:)
    double('authenticator').tap do |authenticator|
      allow(authenticator).to receive(:method_defined?)
                                .with(:status)
                                .and_return(is_status_defined)

      if is_failing_requirements
        allow(authenticator).to receive(:status)
                                  .and_raise("specific-authn-error")
      else
        allow(authenticator).to receive(:status)
      end
    end
  end

  def mock_status_webservice(resource_id)
    double('status_webservice').tap do |status_webservice|
      allow(status_webservice).to receive(:name)
                             .and_return("some-string")

      allow(status_webservice).to receive(:resource_id)
                             .and_return("#{resource_id}/status")
    end
  end

  def mock_webservice(resource_id)
    double('webservice').tap do |webservice|
      allow(webservice).to receive(:name)
                             .and_return("some-string")

      allow(webservice).to receive(:resource_id)
                             .and_return(resource_id)

      allow(webservice).to receive(:status_webservice)
                             .and_return(mock_status_webservice(resource_id))
    end
  end

  def webservices_dict(includes_authenticator:)
    double('webservices_dict').tap do |webservices_dict|
      allow(webservices_dict).to receive(:include?)
                                   .and_return(includes_authenticator)
    end
  end

  def mock_webservices_class
    double('webservices_class').tap do |webservices_class|

      allow(webservices_class).to receive(:from_string)
                                    .with(anything, mock_enabled_authenticators)
                                    .and_return(webservices_dict(includes_authenticator: true))

      allow(webservices_class).to receive(:from_string)
                                    .with(anything, not_including_enabled_authenticators)
                                    .and_return(webservices_dict(includes_authenticator: false))
    end
  end

  let (:mock_implemented_authenticators) do
    {
      'authn-status-pass' => authenticator(is_status_defined: true, is_failing_requirements: false),
      'authn-status-not-implemented' => authenticator(is_status_defined: false, is_failing_requirements: false),
      'authn-status-fail' => authenticator(is_status_defined: true, is_failing_requirements: true)
    }
  end

  # UTs

  context "A valid, whitelisted authenticator" do

    subject do
      Authentication::Status.new(
        role_class: full_access_role_class,
        resource_class: full_access_resource_class,
        webservices_class: mock_webservices_class,
        implemented_authenticators: mock_implemented_authenticators,
        enabled_authenticators: mock_enabled_authenticators
      ).(
        authenticator_name: "authn-status-pass",
          account: test_account,
          authenticator_webservice: mock_webservice("authn-status-pass"),
          user_id: "some-user"
      )
    end

    it "validates without error" do
      expect { subject }.to_not raise_error
    end
  end

  context "A non-existing authenticator" do
    subject do
      Authentication::Status.new(
        role_class: full_access_role_class,
        resource_class: full_access_resource_class,
        webservices_class: mock_webservices_class,
        implemented_authenticators: mock_implemented_authenticators,
        enabled_authenticators: mock_enabled_authenticators
      ).(
        authenticator_name: "authn-non-exist",
          account: test_account,
          authenticator_webservice: mock_webservice("authn-status-pass"),
          user_id: "some-user"
      )
    end

    it "raises an AuthenticatorNotFound error" do
      expect { subject }.to raise_error(Errors::Authentication::AuthenticatorNotFound)
    end
  end


  context "An existing authenticator" do
    context "that does not implement the status check" do

      subject do
        Authentication::Status.new(
          role_class: full_access_role_class,
          resource_class: full_access_resource_class,
          webservices_class: mock_webservices_class,
          implemented_authenticators: mock_implemented_authenticators,
          enabled_authenticators: mock_enabled_authenticators
        ).(
          authenticator_name: "authn-status-not-implemented",
            account: test_account,
            authenticator_webservice: mock_webservice("authn-status-not-implemented"),
            user_id: "some-user"
        )
      end

      it "raises a StatusNotImplemented error" do
        expect { subject }.to raise_error(Errors::Authentication::StatusNotImplemented)
      end
    end

    context "that implements the status check" do

      context "with a non-existing account" do

        subject do
          Authentication::Status.new(
            role_class: full_access_role_class,
            resource_class: full_access_resource_class,
            webservices_class: mock_webservices_class,
            implemented_authenticators: mock_implemented_authenticators,
            enabled_authenticators: mock_enabled_authenticators
          ).(
            authenticator_name: "authn-status-pass",
              account: non_existing_account,
              authenticator_webservice: mock_webservice("authn-status-pass"),
              user_id: "some-user"
          )
        end

        it "raises an AccountNotDefined error" do
          expect { subject }.to raise_error(Errors::Authentication::Security::AccountNotDefined)
        end
      end

      context "with an existing account" do

        context "where the user doesn't have access to the status check" do

          subject do
            Authentication::Status.new(
              role_class: no_access_role_class,
              resource_class: full_access_resource_class,
              webservices_class: mock_webservices_class,
              implemented_authenticators: mock_implemented_authenticators,
              enabled_authenticators: mock_enabled_authenticators
            ).(
              authenticator_name: "authn-status-pass",
                account: test_account,
                authenticator_webservice: mock_webservice("authn-status-pass"),
                user_id: "some-user"
            )
          end

          it "raises a UserNotAuthorizedInConjur error" do
            expect { subject }.to raise_error(Errors::Authentication::Security::UserNotAuthorizedInConjur)
          end

        end

        context "where the operator has access to the status check" do

          context "with a non-existing authenticator webservice" do

            subject do
              Authentication::Status.new(
                role_class: full_access_role_class,
                resource_class: non_existing_resource_class,
                webservices_class: mock_webservices_class,
                implemented_authenticators: mock_implemented_authenticators,
                enabled_authenticators: mock_enabled_authenticators
              ).(
                authenticator_name: "authn-status-pass",
                  account: test_account,
                  authenticator_webservice: mock_webservice("authn-status-pass"),
                  user_id: "some-user"
              )
            end

            it "raises a ServiceNotDefined error" do
              expect { subject }.to raise_error(Errors::Authentication::Security::ServiceNotDefined)
            end

          end

          context "with an existing authenticator webservice" do

            context "and the authenticator is not whitelisted" do

              subject do
                Authentication::Status.new(
                  role_class: full_access_role_class,
                  resource_class: full_access_resource_class,
                  webservices_class: mock_webservices_class,
                  implemented_authenticators: mock_implemented_authenticators,
                  enabled_authenticators: not_including_enabled_authenticators
                ).(
                  authenticator_name: "authn-status-pass",
                    account: test_account,
                    authenticator_webservice: mock_webservice("authn-status-pass"),
                    user_id: "some-user"
                )
              end

              it "raises an NotWhitelisted error" do
                expect { subject }.to raise_error(Errors::Authentication::Security::NotWhitelisted)
              end

            end

            context "and the authenticator is whitelisted" do

              context "with failing specific requirements" do
                subject do
                  Authentication::Status.new(
                    role_class: full_access_role_class,
                    resource_class: full_access_resource_class,
                    webservices_class: mock_webservices_class,
                    implemented_authenticators: mock_implemented_authenticators,
                    enabled_authenticators: mock_enabled_authenticators
                  ).(
                    authenticator_name: "authn-status-fail",
                      account: test_account,
                      authenticator_webservice: mock_webservice("authn-status-fail"),
                      user_id: "some-user"
                  )
                end

                it "raises the same error" do
                  expect { subject }.to raise_error("specific-authn-error")
                end
              end
            end
          end
        end
      end
    end
  end
end