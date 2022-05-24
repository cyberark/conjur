# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnK8s::K8sObjectLookup) do
  def d_variable(value)
    double('variable').tap do |v|
      allow(v).to receive(:secret).and_return(
        double('secret').tap do |v|
          allow(v).to receive(:value).and_return(value)
        end
      )
    end
  end

  let(:webservice) { 
    double('webservice')
  }

  describe "get" do
    it "returns the value of a file if it exists" do

      v = Authentication::AuthnK8s::K8sObjectLookup.new(
        webservice.tap do |ws|
          allow(ws).to receive(:variable).with("kubernetes/config-precedence").and_return(d_variable(nil))
          allow(ws).to receive(:variable).with("kubernetes/ca-cert").and_return(d_variable("from conjur"))
          allow(File).to receive(:exist?).with(Authentication::AuthnK8s::SERVICEACCOUNT_CA_PATH).and_return(true)
          allow(File).to receive(:read).with(Authentication::AuthnK8s::SERVICEACCOUNT_CA_PATH).and_return("from file")
        end
      )
      expect(v.ca_cert).to eq("from file")
    end

    it "returns the value of a file if it exists" do

      v = Authentication::AuthnK8s::K8sObjectLookup.new(
        webservice.tap do |ws|
          allow(ws).to receive(:variable).with("kubernetes/config-precedence").and_return(d_variable("conjur"))
          allow(ws).to receive(:variable).with("kubernetes/ca-cert").and_return(d_variable("from conjur"))
          allow(File).to receive(:exist?).with(Authentication::AuthnK8s::SERVICEACCOUNT_CA_PATH).and_return(true)
          allow(File).to receive(:read).with(Authentication::AuthnK8s::SERVICEACCOUNT_CA_PATH).and_return("from file")
        end
      )
      expect(v.ca_cert).to eq("from conjur")
    end
    
  end
end
