# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Authentication::AuthnJwt::V2::ResolveIdentity) do
  subject do
    Authentication::AuthnJwt::V2::ResolveIdentity.new(
      authenticator: Authentication::AuthnJwt::V2::DataObjects::Authenticator.new(
        **{ account: 'rspec', service_id: 'bar' }.merge(params)
      )
    )
  end

  let(:params) { {} }

  describe '.call' do
    let(:allowed_roles) { [] }
    context 'when role is not found' do
      context 'when id was provided' do
        it 'raise an error' do
          expect { subject.call(identifier: {}, allowed_roles: allowed_roles, id: 'foo-bar') }.to raise_error(
            Errors::Authentication::Security::RoleNotFound
          )
        end
      end
      context 'when role id is inferred' do
        let(:params) { { token_app_property: 'identifier' } }
        it 'raise an error' do
          expect { subject.call(identifier: { 'identifier' => 'fred' }, allowed_roles: allowed_roles) }.to raise_error(
            Errors::Authentication::Security::RoleNotFound
          )
        end
      end
    end
    context 'when id and token app property are not present' do
      it 'raise an error' do
        expect { subject.call(identifier: '', allowed_roles: allowed_roles) }.to raise_error(
          Errors::Authentication::AuthnJwt::IdentityMisconfigured
        )
      end
    end
    context 'when id is present' do
      context 'and token app property is set' do
        let(:params) { { token_app_property: 'foo' } }
        it 'raise an error' do
          expect { subject.call(identifier: '', allowed_roles: allowed_roles, id: 'bar') }.to raise_error(
            Errors::Authentication::AuthnJwt::IdentityMisconfigured
          )
        end
      end
    end
    context 'when token app property is set' do
      let(:params) { { token_app_property: 'foo/bar' } }
      context 'when jwt token does not include the defined claim' do
        let(:identifier) { {} }
        it 'raises an error' do
          expect { subject.call(identifier: identifier, allowed_roles: allowed_roles) }.to raise_error(
            Errors::Authentication::AuthnJwt::NoSuchFieldInToken
          )
        end
      end
      context 'when jwt token includes the defined claim' do
        context 'claim is not a string' do
          context 'claim is an array' do
            let(:identifier) { { 'foo' => { 'bar' => ['hi'] } } }
            it 'raises an error' do
              expect { subject.call(identifier: identifier, allowed_roles: allowed_roles) }.to raise_error(
                Errors::Authentication::AuthnJwt::TokenAppPropertyValueIsNotString
              )
            end
          end
          context 'claim is a hash' do
            let(:identifier) { { 'foo' => { 'bar' => { 'hi' => 'world' } } } }
            it 'raises an error' do
              expect { subject.call(identifier: identifier, allowed_roles: allowed_roles) }.to raise_error(
                Errors::Authentication::AuthnJwt::TokenAppPropertyValueIsNotString
              )
            end
          end
        end
        context 'claim is a string' do
          let(:params) { { token_app_property: 'identifier' } }
          let(:identifier) { { 'identifier' => 'bob', 'project_id' => 'test-1' } }
          let(:allowed_roles) do
            [
              {
                role_id: 'rspec:user:bill',
                annotations: {}
              }, {
                role_id: 'rspec:user:bob',
                annotations: {
                  'authn-jwt/bar/project_id' => 'test-1'
                }
              }
            ]
          end
          context 'when identity path is set' do
            let(:params) { { token_app_property: 'identifier', identity_path: 'some/role' } }
            let(:allowed_roles) do
              [
                {
                  role_id: 'rspec:user:some/role/bill',
                  annotations: {}
                }, {
                  role_id: 'rspec:user:some/role/bob',
                  annotations: {
                    'authn-jwt/bar/project_id' => 'test-1'
                  }
                }
              ]
            end
            it 'finds the user' do
              expect(subject.call(identifier: identifier, allowed_roles: allowed_roles)).to eq(
                'rspec:user:some/role/bob'
              )
            end
          end
          context 'when id is provided (from the url path)' do
            let(:params) { {} }
            it 'finds the user' do
              expect(subject.call(identifier: identifier, allowed_roles: allowed_roles, id: 'bob')).to eq(
                'rspec:user:bob'
              )
            end
          end
          context 'when role is a host' do
            let(:allowed_roles) do
              [
                {
                  role_id: 'rspec:host:some/role/bill',
                  annotations: {}
                }, {
                  role_id: 'rspec:host:bob',
                  annotations: {
                    'authn-jwt/bar/project_id' => 'test-1'
                  }
                }
              ]
            end
            context 'with provided id' do
              let(:params) { {} }
              it 'finds the host' do
                expect(subject.call(identifier: identifier, allowed_roles: allowed_roles, id: 'host/bob')).to eq(
                  'rspec:host:bob'
                )
              end
            end
            context 'id defined in provided JWT' do
              it 'finds the host' do
                expect(subject.call(identifier: identifier, allowed_roles: allowed_roles)).to eq(
                  'rspec:host:bob'
                )
              end
            end
            context 'hosts are missing relevant parameters' do
              context 'missing all annotations' do
                let(:allowed_roles) do
                  [
                    {
                      role_id: 'rspec:host:bill',
                      annotations: {}
                    }, {
                      role_id: 'rspec:host:bob',
                      annotations: {}
                    }
                  ]
                end
                it 'raises an error' do
                  expect { subject.call(identifier: identifier, allowed_roles: allowed_roles) }.to raise_error(
                    Errors::Authentication::Constraints::RoleMissingAnyRestrictions
                  )
                end
              end
            end
            context 'with general authenticator annotations' do
              context 'authenticator annotations does not have a key value' do
                let(:allowed_roles) do
                  [
                    { role_id: 'rspec:host:bill', annotations: {} },
                    { role_id: 'rspec:host:bob',
                      annotations: {
                        'authn-jwt/bar/project_id' => 'test-1',
                        'authn-jwt/bar' => 'test-2',
                        'authn-jwt/fuzz' => 'test-3',
                        'authn-jwt/foo/bar' => 'test-4'
                      }
                    }
                  ]
                end
                let(:identifier) { { 'identifier' => 'bob', 'project_id' => 'test-1', 'fuzz' => 'test-3' } }
                it 'finds the host' do
                  expect(subject.call(identifier: identifier, allowed_roles: allowed_roles)).to eq('rspec:host:bob')
                end
              end
            end
            context 'missing service specific annotations' do
              let(:allowed_roles) do
                [
                  { role_id: 'rspec:host:bill', annotations: {} },
                  { role_id: 'rspec:host:bob',
                    annotations: {
                      'authn-jwt/project_id' => 'test-1'
                    }
                  }
                ]
              end
              it 'raises an error' do
                expect { subject.call(identifier: identifier, allowed_roles: allowed_roles) }.to raise_error(
                  Errors::Authentication::Constraints::RoleMissingAnyRestrictions
                )
              end
            end
            context 'includes enforced claims' do
              let(:params) { { token_app_property: 'identifier', enforced_claims: 'foo, bar' } }
              context 'when enforced claims are missing' do
                let(:allowed_roles) do
                  [
                    { role_id: 'rspec:host:bill', annotations: {} },
                    { role_id: 'rspec:host:bob',
                      annotations: {
                        'authn-jwt/bar/project_id' => 'test-1'
                      }
                    }
                  ]
                end
                it 'raises an error' do
                  expect { subject.call(identifier: identifier, allowed_roles: allowed_roles) }.to raise_error(
                    Errors::Authentication::Constraints::RoleMissingConstraints
                  )
                end
              end
              context 'when enforced_claims are present' do
                let(:allowed_roles) do
                  [
                    { role_id: 'rspec:host:bill', annotations: {} },
                    { role_id: 'rspec:host:bob',
                      annotations: {
                        'authn-jwt/bar/project_id' => 'test-1',
                        'authn-jwt/bar/foo' => 'bing',
                        'authn-jwt/bar/bar' => 'baz'
                      }
                    }
                  ]
                end
                let(:identifier) { { 'identifier' => 'bob', 'project_id' => 'test-1', 'foo' => 'bing', 'bar' => 'baz', 'foo-bar' => 'bing-baz' } }
                it 'finds the host' do
                  expect(subject.call(identifier: identifier, allowed_roles: allowed_roles)).to eq('rspec:host:bob')
                end
                context 'with claim aliases defined' do
                  # TODO: Enforced claims are really confusing because when combined with aliases, it requires
                  # an understanding of the JWT claims. It feels like they should be based on the alias, not the
                  # alias target. This allows you to define the required host annotations, but decouple from the
                  # target JWT claims (which can be mapped as desired using aliases).
                  let(:params) { { token_app_property: 'identifier', enforced_claims: 'qux, quuz', claim_aliases: 'foo:qux, bar: quuz' } }
                  let(:identifier) { { 'identifier' => 'bob', 'project_id' => 'test-1', 'qux' => 'bing', 'quuz' => 'baz', 'foo-bar' => 'bing-baz' } }
                  it 'finds the host' do
                    expect(subject.call(identifier: identifier, allowed_roles: allowed_roles)).to eq('rspec:host:bob')
                  end
                end
              end
            end
          end
          context 'and user is allowed' do
            it 'finds the user' do
              expect(subject.call(identifier: identifier, allowed_roles: allowed_roles)).to eq('rspec:user:bob')
            end
          end
        end
      end
    end
    context 'when host annotations are mis-configured' do
      let(:params) { { token_app_property: 'identifier' } }
      let(:identifier) { { 'identifier' => 'bob', 'project_id' => 'test-1', 'baz' => 'boo' } }
      context 'when attempting to use reserved claims' do
        let(:allowed_roles) do
          [
            { role_id: 'rspec:host:bill', annotations: {} },
            { role_id: 'rspec:user:bob',
              annotations: {
                'authn-jwt/bar/project_id' => 'test-1',
                'authn-jwt/bar/iss' => 'test-2'
              }
            }
          ]
        end
        it 'raises an error' do
          expect { subject.call(identifier: identifier, allowed_roles: allowed_roles) }.to raise_error(
            Errors::Authentication::AuthnJwt::RoleWithRegisteredOrClaimAliasError
          )
        end
      end
      context 'when annotation is empty' do
        let(:allowed_roles) do
          [
            { role_id: 'rspec:host:bill', annotations: {} },
            { role_id: 'rspec:host:bob',
              annotations: {
                'authn-jwt/bar/project_id' => 'test-1',
                'authn-jwt/bar/baz' => ''
              }
            }
          ]
        end
        it 'raises an error' do
          expect { subject.call(identifier: identifier, allowed_roles: allowed_roles) }.to raise_error(
            Errors::Authentication::ResourceRestrictions::EmptyAnnotationGiven
          )
        end
      end
      context 'when annotation values include invalid characters' do
        let(:allowed_roles) do
          [
            { role_id: 'rspec:host:bill', annotations: {} },
            { role_id: 'rspec:host:bob',
              annotations: {
                'authn-jwt/bar/project_id' => 'test-1',
                'authn-jwt/bar/b@z' => 'blah'
              }
            }
          ]
        end
        it 'raises an error' do
          expect { subject.call(identifier: identifier, allowed_roles: allowed_roles) }.to raise_error(
            Errors::Authentication::AuthnJwt::InvalidRestrictionName
          )
        end
      end
      context 'when annotation is an alias' do
        let(:params) { { token_app_property: 'identifier', claim_aliases: 'baz: project_id' } }
        let(:allowed_roles) do
          [
            { role_id: 'rspec:host:bill', annotations: {} },
            { role_id: 'rspec:host:bob',
              annotations: {
                'authn-jwt/bar/project_id' => 'test-1',
                'authn-jwt/bar/baz' => 'test-1'
              }
            }
          ]
        end
        it 'raises an error' do
          expect { subject.call(identifier: identifier, allowed_roles: allowed_roles) }.to raise_error(
            Errors::Authentication::AuthnJwt::RoleWithRegisteredOrClaimAliasError
          )
        end
      end
      context 'when claim alias does not point to an existing annotation' do
        let(:params) { { token_app_property: 'identifier', claim_aliases: 'project_id: baz-1' } }
        let(:allowed_roles) do
          [
            { role_id: 'rspec:host:bill', annotations: {} },
            { role_id: 'rspec:host:bob',
              annotations: {
                'authn-jwt/bar/project_id' => 'test-1',
                'authn-jwt/bar/baz' => 'test-1'
              }
            }
          ]
        end
        it 'raises an error' do
          expect { subject.call(identifier: identifier, allowed_roles: allowed_roles) }.to raise_error(
            Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing
          )
        end
      end
      context 'when annotation value does not match the JWT token value' do
        let(:params) { { token_app_property: 'identifier' } }
        let(:allowed_roles) do
          [
            { role_id: 'rspec:host:bill', annotations: {} },
            { role_id: 'rspec:host:bob',
              annotations: {
                'authn-jwt/bar/project_id' => 'test-1',
                'authn-jwt/bar/baz' => 'test-0'
              }
            }
          ]
        end
        it 'raises an error' do
          expect { subject.call(identifier: identifier, allowed_roles: allowed_roles) }.to raise_error(
            Errors::Authentication::ResourceRestrictions::InvalidResourceRestrictions
          )
        end
      end
      context 'when annotation value is empty' do
        let(:params) { { token_app_property: 'identifier' } }
        let(:identifier) { { 'identifier' => 'bob', 'project_id' => 'test-1', 'baz' => '' } }
        let(:allowed_roles) do
          [
            { role_id: 'rspec:host:bill', annotations: {} },
            { role_id: 'rspec:host:bob',
              annotations: {
                'authn-jwt/bar/project_id' => 'test-1',
                'authn-jwt/bar/baz' => 'test-2'
              }
            }
          ]
        end
        it 'raises an error' do
          expect { subject.call(identifier: identifier, allowed_roles: allowed_roles) }.to raise_error(
            Errors::Authentication::AuthnJwt::JwtTokenClaimIsMissing
          )
        end
      end
    end
  end
end
