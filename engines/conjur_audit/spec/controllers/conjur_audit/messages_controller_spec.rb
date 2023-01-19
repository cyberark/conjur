# frozen_string_literal: true

require 'rails_helper'

module ConjurAudit
  RSpec.describe MessagesController, type: :request do

    describe "GET #index" do
      let(:messages) { JSON.parse response.body }

      it "returns audit messages" do
        add_message "foo"
        get root_path
        expect(response).to have_http_status(:success)
        expect(messages).to match [include('message' => 'foo')]
      end
      
      it "allows filtering" do
        add_message "foo", severity: 4
        add_message "bar", severity: 5
        
        get root_path, params: { severity: 4 }, as: :json

        expect(response).to have_http_status(:success)
        expect(messages.any? { |h| h['message'] == 'foo' }).to be true
      end

      it "supports paging" do
        10.times do |val|
          add_message "#{val} foo"
        end

        get root_path, params: { limit: 4, offset: 2 }

        expect(response).to have_http_status(:success)
        expect(messages.length).to eq(4)

        # The messages will be in reverse chronological order so
        # we expect the result to contain [ 7, 6, 5, 4 ]
        expect(messages[0]).to match include('message' => '7 foo')
        expect(messages[3]).to match include('message' => '4 foo')
      end

      it "returns 404 if no matching entries are found" do
        add_message "bar", severity: 5
        get root_path, params: { severity: 4 }
        expect(response).to have_http_status(:not_found)
      end

      context "with structured data in messages" do
        before do
          add_message "foo", sdata: { foo: { present: true } }
          add_message "bar", sdata: { bar: { present: true } }
        end

        it "allows filtering on sdata" do
          get root_path, params: { 'foo/present' => true }, as: :json
          
          expect(response).to have_http_status(:success)
          expect(messages.any? { |h| h['message'] == 'foo' }).to be true
        end

        it "allows conjur-specific filtering on resources" do
          add_message "resource test", sdata: { "subject@43868": { resource: "acct:kind:id" } }

          get root_path, params: { resource: "acct:kind:id" }

          expect(response).to have_http_status(:success)
          expect(messages).to match [include("message" => "resource test")]
        end

        it "allows conjur-specific filtering on roles" do
          add_message "resource test", sdata: { "subject@43868": { resource: "acct:kind:id" } }
          add_message "role test", sdata: { "subject@43868": { role: "acct:kind:id" } }

          get root_path, params: { role: "acct:kind:id" }

          expect(response).to have_http_status(:success)
          expect(messages).to match [include("message" => "role test")]
        end

        it "allows conjur-specific filtering on entities" do
          add_message "resource test", sdata: { "subject@43868": { resource: "acct:kind:id" } }
          add_message "role test", sdata: { "subject@43868": { role: "acct:kind:id" } }

          get root_path, params: { entity: "acct:kind:id" }

          expect(response).to have_http_status(:success)
          expect(messages).to match_array [
            include("message" => "role test"),
            include("message" => "resource test")
          ]
        end

        it "supports combined queries" do
          add_message "resource test 4v", severity: 4, sdata: { "subject@43868": { resource: "acct:kind:id" }, other: { param: "value" } }
          add_message "resource test 4", severity: 4, sdata: { "subject@43868": { resource: "acct:kind:id" } }
          add_message "resource test 5", severity: 5, sdata: { "subject@43868": { resource: "acct:kind:id" } }
          add_message "resource test 5v", severity: 5, sdata: { "subject@43868": { resource: "acct:kind:id" }, other: { param: "value" } }

          get root_path, params: { resource: "acct:kind:id", severity: 4, 'other/param': 'value' }, as: :json

          expect(response).to have_http_status(:success)
          expect(messages.any? { |h| h['message'] == 'resource test 4v' }).to be true
        end
      end
    end
  end
end
