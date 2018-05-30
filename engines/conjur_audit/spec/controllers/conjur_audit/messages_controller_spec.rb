require 'rails_helper'

module ConjurAudit
  RSpec.describe MessagesController, type: :controller do
    describe "GET #index" do
      let(:messages) { JSON.parse response.body }

      it "returns audit messages" do
        add_message "foo"
        get :index
        expect(response).to have_http_status(:success)
        expect(messages).to match [include('message' => 'foo')]
      end
      
      it "allows filtering" do
        add_message "foo", severity: 4
        add_message "bar", severity: 5
        
        get :index, severity: 4

        expect(response).to have_http_status(:success)
        expect(messages).to match [include('message' => 'foo')]
      end

      it "returns 404 if no matching entries are found" do
        add_message "bar", severity: 5
        get :index, severity: 4
        expect(response).to have_http_status(:not_found)
      end

      context "with structured data in messages" do
        before do
          add_message "foo", sdata: { foo: { present: true } }
          add_message "bar", sdata: { bar: { present: true } }
        end

        it "allows filtering on sdata" do
          get :index, 'foo/present' => true
          expect(response).to have_http_status(:success)
          expect(messages).to match [include('message' => 'foo')]
        end
      end
    end
  end
end
