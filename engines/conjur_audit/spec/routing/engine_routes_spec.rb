# frozen_string_literal: true

require 'rails_helper'

RSpec.describe(ConjurAudit::MessagesController, type: :routing) do
  routes { ConjurAudit::Engine.routes }

  it "routes for role with period in its ID" do
    expect(get: 'roles/cucumber%3Auser%3Amy.user').to(
      route_to(
        controller: 'conjur_audit/messages',
        action: 'index',
        role: 'cucumber:user:my.user'
      )
    ) 
  end

  it "routes for resource with period in its ID" do
    expect(get: 'resources/cucumber%3Auser%3Amy.user').to(
      route_to(
        controller: 'conjur_audit/messages',
        action: 'index',
        resource: 'cucumber:user:my.user'
      )
    )
  end

  it "routes for entity with period in its ID" do
    expect(get: 'entities/cucumber%3Auser%3Amy.user').to(
      route_to(
        controller: 'conjur_audit/messages',
        action: 'index',
        entity: 'cucumber:user:my.user'
      )
    )
  end
end
