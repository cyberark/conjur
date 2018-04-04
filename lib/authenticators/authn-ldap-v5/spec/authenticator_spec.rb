require 'spec_helper'
require 'authenticator'
require 'ldap_server'
require 'rest-client' # Because we need to mock RestClient::Exception because
                      # Conjur API incorrectly returns it instead of wrapping it

describe Authenticator do
	describe "#auth" do

		let(:ldap_server) { double }
		let(:conjur_api) { double }
		subject do
			Authenticator.new(ldap_server: ldap_server, conjur_api: conjur_api)
		end

		context "with a blank username" do
			it "returns false" do
				expect(subject.auth('', 'secret')).to eq(false)
			end
		end

		context "with a blank password" do
			it "returns false" do
				expect(subject.auth('someuser', '')).to eq(false)
			end
		end

		context "with an unexpectedly failing Conjur API" do
			it "returns false" do
				allow(conjur_api).to receive(:authenticate).and_raise('ConjurApiError')
				allow(conjur_api).to(
					receive(:authenticate_local).and_raise('ConjurApiError'))
				allow(ldap_server).to receive(:bind_as).and_return('some result')
				expect(subject.auth('someuser', 'secret')).to eq(false)
			end
		end

		context "without a valid conjur API key as password" do
			context "and an invalid LDAP login" do
				it "returns false" do
					allow(conjur_api).to receive(:authenticate).and_raise(RestClient::Exception)
					allow(ldap_server).to receive(:bind_as).and_return(nil)
					expect(subject.auth('someuser', 'secret')).to eq(false)
				end
			end

			context "but with a valid LDAP login" do

				it "returns a token" do
					allow(conjur_api).to receive(:authenticate).and_raise(RestClient::Exception)
					allow(conjur_api).to(
						receive(:authenticate_local).and_return('some token'))
					# TODO ideally, we'd return a fake LDAP result structure, as using
					#      a string is technically coupling to our implementation, but
					#      this is a minor flaw
					allow(ldap_server).to receive(:bind_as).and_return('some result')
					expect(subject.auth('someuser', 'secret')).to eq('some token')
				end

				context "and a blacklisted LDAP username" do
					it "returns false" do
						allow(conjur_api).to receive(:authenticate).and_raise(RestClient::Exception)
						allow(conjur_api).to(
							receive(:authenticate_local).and_return('some token'))
						allow(ldap_server).to receive(:bind_as).and_return('some result')
						blacklisted_user = 'admin'
						expect(subject.auth(blacklisted_user, 'secret')).to eq(false)
					end
				end

				context "and the LDAP server fails" do
					it "returns false" do
						allow(conjur_api).to receive(:authenticate).and_raise(RestClient::Exception)
						allow(conjur_api).to(
							receive(:authenticate_local).and_return('some token'))
						allow(ldap_server).to receive(:bind_as).and_raise('ServerError')
						expect(subject.auth('someuser', 'secret')).to eq(false)
					end
				end

			end
		end

	end
end
