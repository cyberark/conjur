# frozen_string_literal: true

#Before do
  #ENV['TEST_ENV_NUMBER'] = "1"
#end

Given(/^I create a host factory for layer "([^"]*)"$/) do |layer_id|
  layer_p = Conjur::PolicyParser::Types::Layer.new(layer_id)
  layer_p.owner = Conjur::PolicyParser::Types::Role.new(admin_user.id)
  layer_p.account = "cucumber"

  hf_p = Conjur::PolicyParser::Types::HostFactory.new("#{layer_id}-factory")
  hf_p.account = "cucumber"
  hf_p.owner = Conjur::PolicyParser::Types::Role.new(admin_user.id)
  hf_p.layers = []
  hf_p.layers << layer_p

  [ layer_p, hf_p ].map do |obj|
    Loader::Types.wrap(obj).create!
  end
  @current_resource = @host_factory = Resource[hf_p.resourceid]
end

Given(/^I create a host factory token(?: for "([^"]*)")?$/) do |host_factory_id|
  @host_factory = Resource["cucumber:host_factory:#{host_factory_id}"] if host_factory_id.present?
  expect(@host_factory).to be
  @host_factory_token = HostFactoryToken.create(resource: @host_factory, expiration: Time.now + 10.minutes)
end
