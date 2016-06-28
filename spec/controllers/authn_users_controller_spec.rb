require 'spec_helper'

describe AuthnUsersController, :type => :controller do
  before(:all) do
    AuthnUser.create(login: 'admin', password: 'password') unless AuthnUser['admin']
  end

  before do
    AuthnUser.stub account: 'the-account'
    allow(subject).to receive(:audit_send_api).and_return double.as_null_object
  end

  let(:password) { "password" }
  let(:login) { "u-#{SecureRandom.uuid}" }
  
  context "#show" do
    include_context "create user"
    it "succeeds" do
      allow(controller).to receive(:current_user?).and_return(true)
      allow(controller).to receive(:current_user).and_return(double(:user, account: 'the-account', login: login))
      
      get :show
      expect(response).to be_ok
      expect(JSON.parse(response.body)).to eq(the_user.as_json.stringify_keys)
    end
  end
  
  context "#login" do
    shared_examples_for "successful authentication" do
      it "succeeds" do
        post :login, params
        expect(response).to be_ok
        expect(response.body.length).to be >= 44
      end
    end
    
    shared_examples_for "authentication denied" do
      it "is unauthorized" do
        post :login
        expect(response.code).to eq("401")
      end
    end
    
    context "without auth" do
      it_should_behave_like "authentication denied"
    end
    context "when user doesn't exist" do
      include_context "authenticate Basic"
      it_should_behave_like "authentication denied"
    end
    context "when user exists" do
      include_context "create user"
      context "with basic auth" do
        include_context "authenticate Basic"
        it_should_behave_like "successful authentication"
      end
      context "with Token auth" do
        include_context "authenticate Token"
        it_should_behave_like "authentication denied"
      end
    end
  end
  
  context "#rotate_api_key" do
    shared_examples_for "authentication denied" do
      it "is unauthorized" do
        post :rotate_api_key
        expect(response.code).to eq("401")
      end
    end
    
    context "without auth" do
      it_should_behave_like "authentication denied"
    end
    context "with token auth" do
      include_context "create user"
      include_context "authenticate Token"
      it_should_behave_like "authentication denied"
    end
    context "with basic auth" do
      include_context "authenticate Basic"
      context "user not found" do
        it_should_behave_like "authentication denied"
      end
      context "on valid user" do
        include_context "create user"
        it "rotates the user's API key" do
          api_key = the_user.api_key
          post :rotate_api_key
          the_user.reload
          expect(response.code).to eq("200")
          expect(response.body).to eq(the_user.api_key)
          expect(the_user.api_key).to_not eq(api_key)
        end
      end
    end
  end
  
  context "#update_password" do
    context "without auth" do
      it "is unauthorized" do
        post :update_password
        expect(response.code).to eq("401")
      end
    end
    context "with basic auth" do
      include_context "create user"
      include_context "authenticate Basic"
      context "without post body" do
        it "is is malformed" do
          post :update_password
          expect(response.code).to eq("422")
          expect(response.body).to eq({"password" => "must not be blank"}.to_json)
        end
      end
      context "with post body" do
        let(:user) { double(:user) }
        before { request.env['RAW_POST_DATA'] = password }
        before {
          allow(AuthnUser).to receive(:[]).with(login).and_return user
          expect(user).to receive(:authenticate).with(password).and_return true
          expect(user).to receive(:password=).with(password)
        }
        context "and valid password" do
          let(:password) { "the-password" }
          it "updates the password" do
            expect(user).to receive(:save).and_return true
            post :update_password
            expect(response.code).to eq("204")
          end
        end
        context "and invalid password" do
          let(:password) { "the\npassword" }
          let(:errors) {
            { password: "is invalid" }
          }
          it "reports the error" do
            expect(user).to receive(:save).and_return false
            expect(user).to receive(:errors).and_return errors
            post :update_password
            expect(response.code).to eq("422")
            expect(response.body).to eq(errors.to_json)
          end
        end
      end
    end
  end
end
