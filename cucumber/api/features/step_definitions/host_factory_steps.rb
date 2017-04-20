Given(/^a host factory for layer "([^"]*)"$/) do |layer_id|
  layer_p = Conjur::Policy::Types::Layer.new(layer_id)
  layer_p.owner = Conjur::Policy::Types::Role.new(admin_user.id)
  layer_p.account = "cucumber"

  hf_p = Conjur::Policy::Types::HostFactory.new("#{layer_id}-factory")
  hf_p.account = "cucumber"
  hf_p.owner = Conjur::Policy::Types::Role.new(admin_user.id)
  hf_p.layers = []
  hf_p.layers << layer_p

  [ layer_p, hf_p ].map do |obj|
    Loader::Types.wrap(obj).create!
  end
  @current_resource = @host_factory = Resource[hf_p.resourceid]
end

Given(/^a host factory token$/) do
  expect(@host_factory).to be
  @host_factory_token = HostFactoryToken.create(resource: @host_factory, expiration: Time.now + 10.minutes)
end
