# frozen_string_literal: true

require 'spec_helper'

describe FollowFetchPcloudSecrets do

  subject(:controller) { SecretsController.new }

  context 'Check relevance' do
    before do
      allow(controller).to receive(:account).and_return('rspec')
    end
    it 'Relevance check in host show pcloud secret' do
      allow(controller).to receive(:action_name).and_return("show")
      allow(controller).to receive(:current_user).and_return(double(kind: 'host', id: 'hosty'))
      allow(controller).to receive(:resource_id).and_return('rspec:variable:data/vault/follow_pcloud_secret')
      expect(controller.send(:relevant_call?)).to be_truthy
    end

    it 'Relevance check in host show non-pcloud secret' do
      allow(controller).to receive(:action_name).and_return("show")
      allow(controller).to receive(:current_user).and_return(double(kind: 'host', id: 'hosty'))
      allow(controller).to receive(:resource_id).and_return('rspec:variable:follow_conjur_secret')
      expect(controller.send(:relevant_call?)).to be_falsey
    end

    it 'Relevance check in user show pcloud secret' do
      allow(controller).to receive(:action_name).and_return("show")
      allow(controller).to receive(:current_user).and_return(double(kind: 'user', id: 'user1'))
      allow(controller).to receive(:resource_id).and_return('rspec:variable:data/vault/follow_pcloud_secret')
      expect(controller.send(:relevant_call?)).to be_falsey
    end

    it 'Relevance check in host batch pcloud secret' do
      allow(controller).to receive(:current_user).and_return(double(kind: 'host', id: 'hosty'))
      allow(controller).to receive(:resource_id).and_return(nil)
      allow(controller).to receive(:action_name).and_return("batch")
      allow(controller).to receive(:variable_ids) { ['rspec:variable:data/vault/follow_pcloud_secret'] }
      expect(controller.send(:relevant_call?)).to be_truthy
    end

    it 'Relevance check in host batch non-pcloud secret' do
      allow(controller).to receive(:action_name).and_return("batch")
      allow(controller).to receive(:current_user).and_return(double(kind: 'host', id: 'hosty'))
      allow(controller).to receive(:resource_id).and_return(nil)
      allow(controller).to receive(:variable_ids) { ['rspec:variable:follow_conjur_secret'] }
      expect(controller.send(:relevant_call?)).to be_falsey
    end
  end

  context 'Check first access' do
    before do
      allow(controller).to receive(:account).and_return('rspec')
    end
    it 'Resource is accessed once' do
      controller.class.set_pcloud_access(nil)
      expect(Resource).to receive(:[]).once.and_return(nil)
      controller.send(:first_fetch_set?)
      controller.send(:first_fetch_set?)
    end
  end
end
