require 'spec_helper'

describe 'conjur:init' do
  include_context 'rake'
  
  before { Rake::Task.define_task 'db:migrate' }

  describe '#prerequisites' do
    subject { super().prerequisites }
    it { is_expected.to include('db:migrate') }
  end
  
  def self.key_generation_works
    context "when the Slosilo key is in the environment" do
      before { 
        @authn_slosilo_key = ENV['POSSUM_SLOSILO_KEY']
        ENV['POSSUM_SLOSILO_KEY'] = 'some key'
      }
      after {
        ENV['POSSUM_SLOSILO_KEY'] = @authn_slosilo_key
      }
    end
    
    context "when the Slosilo key is not in the environment" do
      include_context 'tap stdout'
      
      before { 
        @authn_slosilo_key = ENV['POSSUM_SLOSILO_KEY']
        ENV['POSSUM_SLOSILO_KEY'] = nil 
      }
      after {
        ENV['POSSUM_SLOSILO_KEY'] = @authn_slosilo_key
      }
      let(:key) { 'the key' }
      before do
        Slosilo::Symmetric.any_instance.stub random_key: key
      end
      it "generates a random key" do
        subject.invoke
        expect(output).to include('POSSUM_SLOSILO_KEY=dGhlIGtleQ==') # 'the key' base64encoded
      end
    end
  end

  context "when admin user doesn't exist" do
    before { allow(AuthnUser).to receive(:find).with(login: 'admin').and_return nil }
    let(:password) { double "password" }
    before { RandomPasswordGenerator.stub generate: password }
    it "creates it" do
      expect(AuthnUser).to receive(:create).with(login: 'admin', password: password)
      subject.invoke
    end
  end
  
  context "when admin user exists" do
    let(:admin) { double "admin user" }
    before { allow(AuthnUser).to receive(:find).with(login: 'admin').and_return admin }

    it "doesn't try to create it" do
      expect(AuthnUser).not_to receive(:create)
      subject.invoke
    end

    key_generation_works
  end
end
