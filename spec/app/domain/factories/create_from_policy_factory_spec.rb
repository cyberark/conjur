# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Factories::CreateFromPolicyFactory) do
  let(:default_policy_args) do
    {
      loader: Loader::CreatePolicy,
      request_type: 'POST',
      role: 'foo-bar',
      policy: "- !user\n  id: foo\n  annotations:\n    factory: core/v1/user\n",
      request_ip: '127.0.0.1',
      target_policy_id: "rspec:policy:bar"
    }
  end
  let(:policy_response) { SuccessResponse.new('success') }
  let(:policy_loader) do
    spy(CommandHandler::Policy).tap do |double|
      allow(double).to receive(:call).and_return(policy_response)
    end
  end
  let(:secrets_response) { SuccessResponse.new('success')}
  let(:secrets_repository) do
    spy(DB::Repository::SecretsRepository).tap do |double|
      allow(double).to receive(:update).and_return(secrets_response)
    end
  end
  let(:base) do
    Factories::Base.new(
      policy_loader: policy_loader,
      secrets_repository: secrets_repository
    )
  end
  let(:request_method) { 'POST' }

  subject do
    Factories::CreateFromPolicyFactory
      .new(base)
      .call(
        factory_template: factory_template,
        request_body: request,
        account: 'rspec',
        role: 'foo-bar',
        request_ip: '127.0.0.1',
        request_method: request_method
      )
  end

  describe('.call') do
    context 'when using a simple factory' do
      # rubocop:disable Layout/LineLength
      let(:user_factory) { 'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoZFhObGNnb2dJR2xrT2lBOEpUMGdhV1FnSlQ0S1BDVWdhV1lnWkdWbWFXNWxaRDhvYjNkdVpYSmZjbTlzWlNrZ0ppWWdaR1ZtYVc1bFpEOG9iM2R1WlhKZmRIbHdaU2tnTFNVK0NpQWdiM2R1WlhJNklDRThKVDBnYjNkdVpYSmZkSGx3WlNBbFBpQThKVDBnYjNkdVpYSmZjbTlzWlNBbFBnbzhKU0JsYm1RZ0xTVStDandsSUdsbUlHUmxabWx1WldRL0tHbHdYM0poYm1kbEtTQXRKVDRLSUNCeVpYTjBjbWxqZEdWa1gzUnZPaUE4SlQwZ2FYQmZjbUZ1WjJVZ0pUNEtQQ1VnWlc1a0lDMGxQZ29nSUdGdWJtOTBZWFJwYjI1ek9nbzhKU0JoYm01dmRHRjBhVzl1Y3k1bFlXTm9JR1J2SUh4clpYa3NJSFpoYkhWbGZDQXRKVDRLSUNBZ0lEd2xQU0JyWlhrZ0pUNDZJRHdsUFNCMllXeDFaU0FsUGdvOEpTQmxibVFnTFNVK0NnPT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiVXNlciBUZW1wbGF0ZSIsImRlc2NyaXB0aW9uIjoiQ3JlYXRlcyBhIENvbmp1ciBVc2VyIiwidHlwZSI6Im9iamVjdCIsInByb3BlcnRpZXMiOnsiaWQiOnsiZGVzY3JpcHRpb24iOiJVc2VyIElEIiwidHlwZSI6InN0cmluZyJ9LCJhbm5vdGF0aW9ucyI6eyJkZXNjcmlwdGlvbiI6IkFkZGl0aW9uYWwgYW5ub3RhdGlvbnMiLCJ0eXBlIjoib2JqZWN0In0sImJyYW5jaCI6eyJkZXNjcmlwdGlvbiI6IlBvbGljeSBicmFuY2ggdG8gbG9hZCB0aGlzIHJlc291cmNlIGludG8iLCJ0eXBlIjoic3RyaW5nIn0sIm93bmVyX3JvbGUiOnsiZGVzY3JpcHRpb24iOiJUaGUgQ29uanVyIFJvbGUgdGhhdCB3aWxsIG93biB0aGlzIHVzZXIiLCJ0eXBlIjoic3RyaW5nIn0sIm93bmVyX3R5cGUiOnsiZGVzY3JpcHRpb24iOiJUaGUgcmVzb3VyY2UgdHlwZSBvZiB0aGUgb3duZXIgb2YgdGhpcyB1c2VyIiwidHlwZSI6InN0cmluZyJ9LCJpcF9yYW5nZSI6eyJkZXNjcmlwdGlvbiI6IkxpbWl0cyB0aGUgbmV0d29yayByYW5nZSB0aGUgdXNlciBpcyBhbGxvd2VkIHRvIGF1dGhlbnRpY2F0ZSBmcm9tIiwidHlwZSI6InN0cmluZyJ9fSwicmVxdWlyZWQiOlsiYnJhbmNoIiwiaWQiXX19' }
      # rubocop:enable Layout/LineLength
      let(:factory_template) do
        DB::Repository::PolicyFactoryRepository.new.convert_to_data_object(
          encoded_factory: user_factory,
          classification: 'core',
          version: 'v1',
          id: 'user'
        ).result
      end
      context 'when request is invalid' do
        context 'when request body is missing' do
          let(:request) { nil }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq('Request body must be JSON')
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when request body is empty' do
          let(:request) { '' }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq('Request body must be JSON')
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when request body is malformed JSON' do
          let(:request) { '{"foo": "bar }' }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq('Request body must be valid JSON')
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when request body is missing keys' do
          let(:request) { { id: 'foo' }.to_json }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "A value is required for 'branch'", key: 'branch' }])
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when request body is missing values' do
          let(:request) { { id: '', branch: 'foo' }.to_json }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "A value is required for 'id'", key: 'id' }])
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when the request body includes invalid values' do
          let(:request) { { id: 'foo%', branch: 'b@r' }.to_json }
          let(:policy_handler_args) { { target_policy_id: "rspec:policy:br" } }
          it 'submits the expected policy to Conjur with invalid characters removed' do
            expect(subject.success?).to be(true)
            expect(policy_loader).to have_received(:call).with(
              default_policy_args.merge(target_policy_id: 'rspec:policy:br')
            )
          end
        end
        context 'when the request body includes a value from the enumeration' do
          context 'when the factory includes variables with default values' do
            # rubocop:disable Layout/LineLength
            let(:grant_factory) { 'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoWjNKaGJuUUtJQ0J0WlcxaVpYSTZJQ0U4SlQwZ2JXVnRZbVZ5WDNKbGMyOTFjbU5sWDNSNWNHVWdKVDRnUENVOUlHMWxiV0psY2w5eVpYTnZkWEpqWlY5cFpDQWxQZ29nSUhKdmJHVTZJQ0U4SlQwZ2NtOXNaVjl5WlhOdmRYSmpaVjkwZVhCbElDVStJRHdsUFNCeWIyeGxYM0psYzI5MWNtTmxYMmxrSUNVK0NnPT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiR3JhbnQgVGVtcGxhdGUiLCJkZXNjcmlwdGlvbiI6IkFzc2lnbnMgYSBSb2xlIHRvIGFub3RoZXIgUm9sZSIsInR5cGUiOiJvYmplY3QiLCJwcm9wZXJ0aWVzIjp7ImlkIjp7ImRlc2NyaXB0aW9uIjoiUmVzb3VyY2UgSWRlbnRpZmllciIsInR5cGUiOiJzdHJpbmcifSwiYW5ub3RhdGlvbnMiOnsiZGVzY3JpcHRpb24iOiJBZGRpdGlvbmFsIGFubm90YXRpb25zIiwidHlwZSI6Im9iamVjdCJ9LCJicmFuY2giOnsiZGVzY3JpcHRpb24iOiJQb2xpY3kgYnJhbmNoIHRvIGxvYWQgdGhpcyBncmFudCBpbnRvIiwidHlwZSI6InN0cmluZyJ9LCJtZW1iZXJfcmVzb3VyY2VfdHlwZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSBtZW1iZXIgdHlwZSAoZ3JvdXAsIGhvc3QsIHVzZXIsIG9yIGxheWVyKSBmb3IgdGhlIGdyYW50IiwidHlwZSI6InN0cmluZyIsImVudW0iOlsiZ3JvdXAiLCJob3N0IiwidXNlciIsImxheWVyIl19LCJtZW1iZXJfcmVzb3VyY2VfaWQiOnsiZGVzY3JpcHRpb24iOiJUaGUgbWVtYmVyIHJlc291cmNlIGlkZW50aWZpZXIgZm9yIHRoZSBncmFudCIsInR5cGUiOiJzdHJpbmcifSwicm9sZV9yZXNvdXJjZV90eXBlIjp7ImRlc2NyaXB0aW9uIjoiVGhlIHJvbGUgdHlwZSAoZ3JvdXAgb3IgbGF5ZXIpIGZvciB0aGUgZ3JhbnQiLCJ0eXBlIjoic3RyaW5nIiwiZGVmYXVsdCI6Imdyb3VwIiwiZW51bSI6WyJncm91cCIsImxheWVyIl19LCJyb2xlX3Jlc291cmNlX2lkIjp7ImRlc2NyaXB0aW9uIjoiVGhlIHJvbGUgcmVzb3VyY2UgaWRlbnRpZmllciBmb3IgdGhlIGdyYW50IiwidHlwZSI6InN0cmluZyJ9fSwicmVxdWlyZWQiOlsiYnJhbmNoIiwibWVtYmVyX3Jlc291cmNlX3R5cGUiLCJtZW1iZXJfcmVzb3VyY2VfaWQiLCJyb2xlX3Jlc291cmNlX3R5cGUiLCJyb2xlX3Jlc291cmNlX2lkIl19fQ==' }
            # rubocop:enable Layout/LineLength
            let(:factory_template) do
              DB::Repository::PolicyFactoryRepository.new.convert_to_data_object(
                encoded_factory: grant_factory,
                classification: 'core',
                version: 'v1',
                id: 'grant'
              ).result
            end
            context 'when the request body includes a value for the default' do
              let(:request) do
                {
                  branch: 'bar',
                  member_resource_type: 'group',
                  member_resource_id: 'foo',
                  role_resource_type: 'layer',
                  role_resource_id: 'bar'
                }.to_json
              end
              it 'submits the policy with the provided values' do
                expect(subject.success?).to be(true)
                expect(policy_loader).to have_received(:call).with(
                  default_policy_args.merge(target_policy_id: 'rspec:policy:bar', policy: "- !grant\n  member: !group foo\n  role: !layer bar\n")
                )
              end
            end
            context 'when the request body does not include a value for an input with a default' do
              let(:request) do
                {
                  branch: 'bar',
                  member_resource_type: 'group',
                  member_resource_id: 'foo',
                  role_resource_id: 'bar'
                }.to_json
              end
              it 'submits the policy with the provided values' do
                expect(subject.success?).to be(true)
                expect(policy_loader).to have_received(:call).with(
                  default_policy_args.merge(
                    target_policy_id: 'rspec:policy:bar',
                    policy: "- !grant\n  member: !group foo\n  role: !group bar\n"
                  )
                )
              end
            end
          end
        end
        context 'when the request body does not include a value from the enumeration' do
          # rubocop:disable Layout/LineLength
          let(:grant_factory) { 'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoWjNKaGJuUUtJQ0J0WlcxaVpYSTZJQ0U4SlQwZ2JXVnRZbVZ5WDNKbGMyOTFjbU5sWDNSNWNHVWdKVDRnUENVOUlHMWxiV0psY2w5eVpYTnZkWEpqWlY5cFpDQWxQZ29nSUhKdmJHVTZJQ0U4SlQwZ2NtOXNaVjl5WlhOdmRYSmpaVjkwZVhCbElDVStJRHdsUFNCeWIyeGxYM0psYzI5MWNtTmxYMmxrSUNVK0NnPT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiR3JhbnQgVGVtcGxhdGUiLCJkZXNjcmlwdGlvbiI6IkFzc2lnbnMgYSBSb2xlIHRvIGFub3RoZXIgUm9sZSIsInR5cGUiOiJvYmplY3QiLCJwcm9wZXJ0aWVzIjp7ImlkIjp7ImRlc2NyaXB0aW9uIjoiUmVzb3VyY2UgSWRlbnRpZmllciIsInR5cGUiOiJzdHJpbmcifSwiYW5ub3RhdGlvbnMiOnsiZGVzY3JpcHRpb24iOiJBZGRpdGlvbmFsIGFubm90YXRpb25zIiwidHlwZSI6Im9iamVjdCJ9LCJicmFuY2giOnsiZGVzY3JpcHRpb24iOiJQb2xpY3kgYnJhbmNoIHRvIGxvYWQgdGhpcyBncmFudCBpbnRvIiwidHlwZSI6InN0cmluZyJ9LCJtZW1iZXJfcmVzb3VyY2VfdHlwZSI6eyJkZXNjcmlwdGlvbiI6IlRoZSBtZW1iZXIgdHlwZSAoZ3JvdXAsIGhvc3QsIHVzZXIsIG9yIGxheWVyKSBmb3IgdGhlIGdyYW50IiwidHlwZSI6InN0cmluZyIsImVudW0iOlsiZ3JvdXAiLCJob3N0IiwidXNlciIsImxheWVyIl19LCJtZW1iZXJfcmVzb3VyY2VfaWQiOnsiZGVzY3JpcHRpb24iOiJUaGUgbWVtYmVyIHJlc291cmNlIGlkZW50aWZpZXIgZm9yIHRoZSBncmFudCIsInR5cGUiOiJzdHJpbmcifSwicm9sZV9yZXNvdXJjZV90eXBlIjp7ImRlc2NyaXB0aW9uIjoiVGhlIHJvbGUgdHlwZSAoZ3JvdXAgb3IgbGF5ZXIpIGZvciB0aGUgZ3JhbnQiLCJ0eXBlIjoic3RyaW5nIiwiZGVmYXVsdCI6Imdyb3VwIiwiZW51bSI6WyJncm91cCIsImxheWVyIl19LCJyb2xlX3Jlc291cmNlX2lkIjp7ImRlc2NyaXB0aW9uIjoiVGhlIHJvbGUgcmVzb3VyY2UgaWRlbnRpZmllciBmb3IgdGhlIGdyYW50IiwidHlwZSI6InN0cmluZyJ9fSwicmVxdWlyZWQiOlsiYnJhbmNoIiwibWVtYmVyX3Jlc291cmNlX3R5cGUiLCJtZW1iZXJfcmVzb3VyY2VfaWQiLCJyb2xlX3Jlc291cmNlX3R5cGUiLCJyb2xlX3Jlc291cmNlX2lkIl19fQ==' }
          # rubocop:enable Layout/LineLength
          let(:factory_template) do
            DB::Repository::PolicyFactoryRepository.new.convert_to_data_object(
              encoded_factory: grant_factory,
              classification: 'core',
              version: 'v1',
              id: 'grant'
            ).result
          end
          let(:request) do
            {
              branch: 'bar',
              member_resource_type: 'baz',
              member_resource_id: 'foo',
              role_resource_type: 'layer',
              role_resource_id: 'bar'
            }.to_json
          end
          it 'returns an error response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "Value must be one of: 'group', 'host', 'user', 'layer'", key: 'member_resource_type' }])
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when the request body includes a values with a comma' do
          # rubocop:disable Layout/LineLength
          let(:permit_factory) { 'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoY0dWeWJXbDBDaUFnY205c1pUb2dJVHdsUFNCeWIyeGxYM1I1Y0dVZ0pUNGdQQ1U5SUhKdmJHVmZhV1FnSlQ0S0lDQnlaWE52ZFhKalpUb2dJVHdsUFNCeVpYTnZkWEpqWlY5MGVYQmxJQ1UrSUR3bFBTQnlaWE52ZFhKalpWOXBaQ0FsUGdvZ0lIQnlhWFpwYkdWblpYTTZJRnM4SlQwZ2NISnBkbWxzWldkbGN5QWxQbDBLIiwicG9saWN5X2JyYW5jaCI6Ilx1MDAzYyU9IGJyYW5jaCAlXHUwMDNlIiwic2NoZW1hIjp7IiRzY2hlbWEiOiJodHRwOi8vanNvbi1zY2hlbWEub3JnL2RyYWZ0LTA2L3NjaGVtYSMiLCJ0aXRsZSI6IlBlcm1pdCBUZW1wbGF0ZSIsImRlc2NyaXB0aW9uIjoiQXNzaWducyBwZXJtaXNzaW9ucyB0byBhIFJvbGUiLCJ0eXBlIjoib2JqZWN0IiwicHJvcGVydGllcyI6eyJhbm5vdGF0aW9ucyI6eyJkZXNjcmlwdGlvbiI6IkFkZGl0aW9uYWwgYW5ub3RhdGlvbnMiLCJ0eXBlIjoib2JqZWN0In0sImJyYW5jaCI6eyJkZXNjcmlwdGlvbiI6IlBvbGljeSBicmFuY2ggdG8gbG9hZCB0aGlzIHBlcm1pdCBpbnRvIiwidHlwZSI6InN0cmluZyJ9LCJyb2xlX3R5cGUiOnsiZGVzY3JpcHRpb24iOiJUaGUgcm9sZSB0eXBlIHRvIGdyYW50IHBlcm1pc3Npb24gb24gYSByZXNvdXJjZSIsInR5cGUiOiJzdHJpbmciLCJlbnVtIjpbImdyb3VwIiwiaG9zdCIsImxheWVyIiwicG9saWN5IiwidXNlciJdfSwicm9sZV9pZCI6eyJkZXNjcmlwdGlvbiI6IlRoZSByb2xlIGlkZW50aWZpZXIgdG8gZ3JhbnQgcGVybWlzc2lvbiBvbiBhIHJlc291cmNlIiwidHlwZSI6InN0cmluZyJ9LCJyZXNvdXJjZV90eXBlIjp7ImRlc2NyaXB0aW9uIjoiVGhlIHJlc291cmNlIHR5cGUgdG8gZ3JhbnQgdGhlIHBlcm1pc3Npb24gb24iLCJ0eXBlIjoic3RyaW5nIiwiZW51bSI6WyJncm91cCIsImhvc3QiLCJsYXllciIsInBvbGljeSIsInVzZXIiLCJ2YXJpYWJsZSJdfSwicmVzb3VyY2VfaWQiOnsiZGVzY3JpcHRpb24iOiJUaGUgcmVzb3VyY2UgaWRlbnRpZmllciB0byBncmFudCB0aGUgcGVybWlzc2lvbiBvbiIsInR5cGUiOiJzdHJpbmcifSwicHJpdmlsZWdlcyI6eyJkZXNjcmlwdGlvbiI6IkNvbW1hIHNlcGVyYXRlZCBsaXN0IG9mIHByaXZpbGVnZXMgdG8gZ3JhbnQgb24gdGhlIHJlc291cmNlIiwidHlwZSI6InN0cmluZyJ9fSwicmVxdWlyZWQiOlsiYnJhbmNoIiwicm9sZV90eXBlIiwicm9sZV9pZCIsInJlc291cmNlX3R5cGUiLCJyZXNvdXJjZV9pZCIsInByaXZpbGVnZXMiXX19' }
          # rubocop:enable Layout/LineLength
          let(:factory_template) do
            DB::Repository::PolicyFactoryRepository.new.convert_to_data_object(
              encoded_factory: permit_factory,
              classification: 'core',
              version: 'v1',
              id: 'permit'
            ).result
          end
          let(:request) do
            {
              branch: 'foo-bar',
              resource_type: 'variable',
              resource_id: 'foo',
              role_type: 'layer',
              role_id: 'bar',
              privileges: 'read, write'
            }.to_json
          end
          it 'submits the policy with the provided values' do
            expect(subject.success?).to be(true)
            expect(policy_loader).to have_received(:call).with(
              default_policy_args.merge(
                target_policy_id: 'rspec:policy:foo-bar',
                policy: "- !permit\n  role: !layer bar\n  resource: !variable foo\n  privileges: [read,write]\n"
              )
            )
          end
        end
      end
      context 'when request body is valid' do
        let(:request) { { id: 'foo', branch: 'bar' }.to_json }
        it 'submits the expected policy to Conjur' do
          expect(subject.success?).to be(true)
          expect(policy_loader).to have_received(:call).with(default_policy_args)
        end
        context 'when inputs include a hash (ex. for annotations)' do
          let(:request) { { id: 'foo', branch: 'bar', annotations: { 'foo' => 'bar', 'bing' => 'bang' } }.to_json }
          it 'submits the expected policy to Conjur' do
            expect(subject.success?).to be(true)
            expect(policy_loader).to have_received(:call).with(
              default_policy_args.merge(
                policy: "- !user\n  id: foo\n  annotations:\n    foo: bar\n    bing: bang\n    factory: core/v1/user\n"
              )
            )
          end
        end
        context 'when a factory is applied with an appropriate verb' do
          context 'when verb is POST' do
            let(:request_method) { 'POST' }
            it 'is successful' do
              expect(subject.success?).to be(true)
              expect(policy_loader).to have_received(:call).with(
                default_policy_args.merge(request_type: 'POST')
              )
            end
          end
          context 'when verb is PATCH' do
            let(:request_method) { 'PATCH' }
            it 'is successful' do
              expect(subject.success?).to be(true)
              expect(policy_loader).to have_received(:call).with(
                default_policy_args.merge(request_type: 'PATCH')
              )
            end
          end
        end
        context 'when a factory is applied with an inappropriate verb' do
          context 'when verb is DELETE' do
            let(:request_method) { 'DELETE' }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.message).to eq("Request method must be POST or PATCH")
              expect(subject.exception).to be_a(Errors::Factories::InvalidAction)
              expect(subject.exception.message).to eq("CONJ00160E Invalid action: 'DELETE', only POST or PATCH are allowed")
              expect(subject.status).to eq(:bad_request)
              expect(policy_loader).to_not have_received(:call).with(
                default_policy_args.merge(request_type: 'DELETE')
              )
            end
          end
          context 'when verb is GET' do
            let(:request_method) { 'GET' }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.message).to eq("Request method must be POST or PATCH")
              expect(subject.exception).to be_a(Errors::Factories::InvalidAction)
              expect(subject.exception.message).to eq("CONJ00160E Invalid action: 'GET', only POST or PATCH are allowed")
              expect(subject.status).to eq(:bad_request)
              expect(policy_loader).to_not have_received(:call).with(
                default_policy_args.merge(request_type: 'GET')
              )
            end
          end
          context 'when verb is PUT' do
            let(:request_method) { 'PUT' }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.message).to eq("Request method must be POST or PATCH")
              expect(subject.exception).to be_a(Errors::Factories::InvalidAction)
              expect(subject.exception.message).to eq("CONJ00160E Invalid action: 'PUT', only POST or PATCH are allowed")
              expect(subject.status).to eq(:bad_request)
              expect(policy_loader).to_not have_received(:call).with(
                default_policy_args.merge(request_type: 'PUT')
              )
            end
          end
          context 'when verb is CONNECT' do
            let(:request_method) { 'CONNECT' }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.message).to eq("Request method must be POST or PATCH")
              expect(subject.exception).to be_a(Errors::Factories::InvalidAction)
              expect(subject.exception.message).to eq("CONJ00160E Invalid action: 'CONNECT', only POST or PATCH are allowed")
              expect(subject.status).to eq(:bad_request)
              expect(policy_loader).to_not have_received(:call).with(
                default_policy_args.merge(request_type: 'CONNECT')
              )
            end
          end
          context 'when verb is OPTONS' do
            let(:request_method) { 'OPTONS' }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.message).to eq("Request method must be POST or PATCH")
              expect(subject.exception).to be_a(Errors::Factories::InvalidAction)
              expect(subject.exception.message).to eq("CONJ00160E Invalid action: 'OPTONS', only POST or PATCH are allowed")
              expect(subject.status).to eq(:bad_request)
              expect(policy_loader).to_not have_received(:call).with(
                default_policy_args.merge(request_type: 'OPTONS')
              )
            end
          end
          context 'when verb is TRACE' do
            let(:request_method) { 'TRACE' }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.message).to eq("Request method must be POST or PATCH")
              expect(subject.exception).to be_a(Errors::Factories::InvalidAction)
              expect(subject.exception.message).to eq("CONJ00160E Invalid action: 'TRACE', only POST or PATCH are allowed")
              expect(subject.status).to eq(:bad_request)
              expect(policy_loader).to_not have_received(:call).with(
                default_policy_args.merge(request_type: 'TRACE')
              )
            end
          end
          context 'when verb is HEAD' do
            let(:request_method) { 'HEAD' }
            it 'is unsuccessful' do
              expect(subject.success?).to be(false)
              expect(subject.message).to eq("Request method must be POST or PATCH")
              expect(subject.exception).to be_a(Errors::Factories::InvalidAction)
              expect(subject.exception.message).to eq("CONJ00160E Invalid action: 'HEAD', only POST or PATCH are allowed")
              expect(subject.status).to eq(:bad_request)
              expect(policy_loader).to_not have_received(:call).with(
                default_policy_args.merge(request_type: 'HEAD')
              )
            end
          end
        end
      end
    end
    context 'when using a complex factory' do
      # rubocop:disable Layout/LineLength
      let(:database_factory) { 'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoY0c5c2FXTjVDaUFnYVdRNklEd2xQU0JwWkNBbFBnb2dJR0Z1Ym05MFlYUnBiMjV6T2dvOEpTQmhibTV2ZEdGMGFXOXVjeTVsWVdOb0lHUnZJSHhyWlhrc0lIWmhiSFZsZkNBdEpUNEtJQ0FnSUR3bFBTQnJaWGtnSlQ0NklEd2xQU0IyWVd4MVpTQWxQZ284SlNCbGJtUWdMU1UrQ2dvZ0lHSnZaSGs2Q2lBZ0xTQW1kbUZ5YVdGaWJHVnpDaUFnSUNBdElDRjJZWEpwWVdKc1pTQjFjbXdLSUNBZ0lDMGdJWFpoY21saFlteGxJSEJ2Y25RS0lDQWdJQzBnSVhaaGNtbGhZbXhsSUhWelpYSnVZVzFsQ2lBZ0lDQXRJQ0YyWVhKcFlXSnNaU0J3WVhOemQyOXlaQW9nSUNBZ0xTQWhkbUZ5YVdGaWJHVWdjM05zTFdObGNuUnBabWxqWVhSbENpQWdJQ0F0SUNGMllYSnBZV0pzWlNCemMyd3RhMlY1Q2lBZ0lDQXRJQ0YyWVhKcFlXSnNaU0J6YzJ3dFkyRXRZMlZ5ZEdsbWFXTmhkR1VLQ2lBZ0xTQWhaM0p2ZFhBZ1kyOXVjM1Z0WlhKekNpQWdMU0FoWjNKdmRYQWdZV1J0YVc1cGMzUnlZWFJ2Y25NS0lDQUtJQ0FqSUdOdmJuTjFiV1Z5Y3lCallXNGdjbVZoWkNCaGJtUWdaWGhsWTNWMFpRb2dJQzBnSVhCbGNtMXBkQW9nSUNBZ2NtVnpiM1Z5WTJVNklDcDJZWEpwWVdKc1pYTUtJQ0FnSUhCeWFYWnBiR1ZuWlhNNklGc2djbVZoWkN3Z1pYaGxZM1YwWlNCZENpQWdJQ0J5YjJ4bE9pQWhaM0p2ZFhBZ1kyOXVjM1Z0WlhKekNpQWdDaUFnSXlCaFpHMXBibWx6ZEhKaGRHOXljeUJqWVc0Z2RYQmtZWFJsSUNoaGJtUWdjbVZoWkNCaGJtUWdaWGhsWTNWMFpTd2dkbWxoSUhKdmJHVWdaM0poYm5RcENpQWdMU0FoY0dWeWJXbDBDaUFnSUNCeVpYTnZkWEpqWlRvZ0tuWmhjbWxoWW14bGN3b2dJQ0FnY0hKcGRtbHNaV2RsY3pvZ1d5QjFjR1JoZEdVZ1hRb2dJQ0FnY205c1pUb2dJV2R5YjNWd0lHRmtiV2x1YVhOMGNtRjBiM0p6Q2lBZ0NpQWdJeUJoWkcxcGJtbHpkSEpoZEc5eWN5Qm9ZWE1nY205c1pTQmpiMjV6ZFcxbGNuTUtJQ0F0SUNGbmNtRnVkQW9nSUNBZ2JXVnRZbVZ5T2lBaFozSnZkWEFnWVdSdGFXNXBjM1J5WVhSdmNuTUtJQ0FnSUhKdmJHVTZJQ0ZuY205MWNDQmpiMjV6ZFcxbGNuTT0iLCJwb2xpY3lfYnJhbmNoIjoiXHUwMDNjJT0gYnJhbmNoICVcdTAwM2UiLCJzY2hlbWEiOnsiJHNjaGVtYSI6Imh0dHA6Ly9qc29uLXNjaGVtYS5vcmcvZHJhZnQtMDYvc2NoZW1hIyIsInRpdGxlIjoiRGF0YWJhc2UgQ29ubmVjdGlvbiBUZW1wbGF0ZSIsImRlc2NyaXB0aW9uIjoiQWxsIGluZm9ybWF0aW9uIGZvciBjb25uZWN0aW5nIHRvIGEgZGF0YWJhc2UiLCJ0eXBlIjoib2JqZWN0IiwicHJvcGVydGllcyI6eyJpZCI6eyJkZXNjcmlwdGlvbiI6IlJlc291cmNlIElkZW50aWZpZXIiLCJ0eXBlIjoic3RyaW5nIn0sImFubm90YXRpb25zIjp7ImRlc2NyaXB0aW9uIjoiQWRkaXRpb25hbCBhbm5vdGF0aW9ucyIsInR5cGUiOiJvYmplY3QifSwiYnJhbmNoIjp7ImRlc2NyaXB0aW9uIjoiUG9saWN5IGJyYW5jaCB0byBsb2FkIHRoaXMgcmVzb3VyY2UgaW50byIsInR5cGUiOiJzdHJpbmcifSwidmFyaWFibGVzIjp7InR5cGUiOiJvYmplY3QiLCJwcm9wZXJ0aWVzIjp7InVybCI6eyJkZXNjcmlwdGlvbiI6IkRhdGFiYXNlIFVSTCIsInR5cGUiOiJzdHJpbmcifSwicG9ydCI6eyJkZXNjcmlwdGlvbiI6IkRhdGFiYXNlIFBvcnQiLCJ0eXBlIjoic3RyaW5nIn0sInVzZXJuYW1lIjp7ImRlc2NyaXB0aW9uIjoiRGF0YWJhc2UgVXNlcm5hbWUiLCJ0eXBlIjoic3RyaW5nIn0sInBhc3N3b3JkIjp7ImRlc2NyaXB0aW9uIjoiRGF0YWJhc2UgUGFzc3dvcmQiLCJ0eXBlIjoic3RyaW5nIn0sInNzbC1jZXJ0aWZpY2F0ZSI6eyJkZXNjcmlwdGlvbiI6IkNsaWVudCBTU0wgQ2VydGlmaWNhdGUiLCJ0eXBlIjoic3RyaW5nIn0sInNzbC1rZXkiOnsiZGVzY3JpcHRpb24iOiJDbGllbnQgU1NMIEtleSIsInR5cGUiOiJzdHJpbmcifSwic3NsLWNhLWNlcnRpZmljYXRlIjp7ImRlc2NyaXB0aW9uIjoiQ0EgUm9vdCBDZXJ0aWZpY2F0ZSIsInR5cGUiOiJzdHJpbmcifX0sInJlcXVpcmVkIjpbInVybCIsInBvcnQiLCJ1c2VybmFtZSIsInBhc3N3b3JkIl19fSwicmVxdWlyZWQiOlsiYnJhbmNoIiwiaWQiLCJ2YXJpYWJsZXMiXX19' }
      # rubocop:enable Layout/LineLength
      let(:factory_template) do
        DB::Repository::PolicyFactoryRepository.new.convert_to_data_object(
          encoded_factory: database_factory,
          classification: 'connections',
          version: 'v1',
          id: 'database'
        ).result
      end
      let(:request) { { id: 'bar', branch: 'foo', variables: variables }.to_json }
      # rubocop:disable Layout/LineLength
      let(:policy_body) { "- !policy\n  id: bar\n  annotations:\n    factory: connections/v1/database\n\n  body:\n  - &variables\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n    - !variable ssl-certificate\n    - !variable ssl-key\n    - !variable ssl-ca-certificate\n\n  - !group consumers\n  - !group administrators\n  \n  # consumers can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group consumers\n  \n  # administrators can update (and read and execute, via role grant)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators\n  \n  # administrators has role consumers\n  - !grant\n    member: !group administrators\n    role: !group consumers" }
      # rubocop:enable Layout/LineLength
      context 'when request body is missing values' do
        let(:variables) { { port: '1234', url: 'http://localhost', username: 'super-user' } }
        it 'returns a failure response' do
          expect(subject.success?).to be(false)
          expect(subject.message).to eq([{ message: "A value is required for '/variables/password'", key: '/variables/password' }])
          expect(subject.status).to eq(:bad_request)
        end
      end
      context 'when variable value is not a string' do
        context 'when value is an integer' do
          let(:variables) { { port: 1234, url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "Validation error: '/variables/port' must be a string" }])
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when value is a boolean' do
          let(:variables) { { port: true, url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "Validation error: '/variables/port' must be a string" }])
            expect(subject.status).to eq(:bad_request)
          end
        end
        context 'when value is null' do
          let(:variables) { { port: nil, url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
          it 'returns a failure response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "Validation error: '/variables/port' must be a string" }])
            expect(subject.status).to eq(:bad_request)
          end
        end
      end
      context 'when request body includes required values' do
        let(:variables) { { port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
        it 'applies policy and variables' do
          expect(subject.success?).to be(true)
          expect(policy_loader).to have_received(:call).with(
            # rubocop:disable Layout/LineLength
            default_policy_args.merge(
              target_policy_id: 'rspec:policy:foo',
              policy: "- !policy\n  id: bar\n  annotations:\n    factory: connections/v1/database\n\n  body:\n  - &variables\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n    - !variable ssl-certificate\n    - !variable ssl-key\n    - !variable ssl-ca-certificate\n\n  - !group consumers\n  - !group administrators\n  \n  # consumers can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group consumers\n  \n  # administrators can update (and read and execute, via role grant)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators\n  \n  # administrators has role consumers\n  - !grant\n    member: !group administrators\n    role: !group consumers"
            )
            # rubocop:enable Layout/LineLength
          )
          expect(secrets_repository).to have_received(:update).with(
            account: 'rspec',
            role: 'foo-bar',
            variables: {
              'foo/bar/port' => '1234',
              'foo/bar/url' => 'http://localhost',
              'foo/bar/username' => 'super-user',
              'foo/bar/password' => 'foo-bar'
            }
          )
        end
        context 'when factory is applied to the root policy namespace' do
          let(:request) { { id: 'bar', branch: 'root', variables: variables }.to_json }
          it 'does not append "root" to the variables' do
            expect(subject.success?).to be(true)
            expect(policy_loader).to have_received(:call).with(
              # rubocop:disable Layout/LineLength
              default_policy_args.merge(
                target_policy_id: 'rspec:policy:root',
                policy: "- !policy\n  id: bar\n  annotations:\n    factory: connections/v1/database\n\n  body:\n  - &variables\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n    - !variable ssl-certificate\n    - !variable ssl-key\n    - !variable ssl-ca-certificate\n\n  - !group consumers\n  - !group administrators\n  \n  # consumers can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group consumers\n  \n  # administrators can update (and read and execute, via role grant)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators\n  \n  # administrators has role consumers\n  - !grant\n    member: !group administrators\n    role: !group consumers"
              )
              # rubocop:enable Layout/LineLength
            )
            expect(secrets_repository).to have_received(:update).with(
              account: 'rspec',
              role: 'foo-bar',
              variables: {
                'bar/port' => '1234',
                'bar/url' => 'http://localhost',
                'bar/username' => 'super-user',
                'bar/password' => 'foo-bar'
              }
            )
          end
        end
      end
      context 'when request body includes required and optional values' do
        let(:variables) { { port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar', 'ssl-certificate': 'cert-body', 'ssl-key': 'cert-key-body' } }
        it 'applies policy and relevant variables' do
          expect(subject.success?).to be(true)
          expect(policy_loader).to have_received(:call).with(
            # rubocop:disable Layout/LineLength
            default_policy_args.merge(
              target_policy_id: 'rspec:policy:foo',
              policy: "- !policy\n  id: bar\n  annotations:\n    factory: connections/v1/database\n\n  body:\n  - &variables\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n    - !variable ssl-certificate\n    - !variable ssl-key\n    - !variable ssl-ca-certificate\n\n  - !group consumers\n  - !group administrators\n  \n  # consumers can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group consumers\n  \n  # administrators can update (and read and execute, via role grant)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators\n  \n  # administrators has role consumers\n  - !grant\n    member: !group administrators\n    role: !group consumers"
            )
            # rubocop:enable Layout/LineLength
          )
          expect(secrets_repository).to have_received(:update).with(
            account: 'rspec',
            role: 'foo-bar',
            variables: {
              'foo/bar/port' => '1234',
              'foo/bar/url' => 'http://localhost',
              'foo/bar/username' => 'super-user',
              'foo/bar/password' => 'foo-bar',
              'foo/bar/ssl-certificate' => 'cert-body',
              'foo/bar/ssl-key' => 'cert-key-body'
            }
          )
        end
      end
      context 'when request body includes extra variable values' do
        let(:variables) { { foo: 'bar', port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
        it 'only saves variables defined in the factory' do
          expect(subject.success?).to be(true)
          expect(policy_loader).to have_received(:call).with(
            # rubocop:disable Layout/LineLength
            default_policy_args.merge(
              target_policy_id: 'rspec:policy:foo',
              policy: "- !policy\n  id: bar\n  annotations:\n    factory: connections/v1/database\n\n  body:\n  - &variables\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n    - !variable ssl-certificate\n    - !variable ssl-key\n    - !variable ssl-ca-certificate\n\n  - !group consumers\n  - !group administrators\n  \n  # consumers can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group consumers\n  \n  # administrators can update (and read and execute, via role grant)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators\n  \n  # administrators has role consumers\n  - !grant\n    member: !group administrators\n    role: !group consumers"
            )
            # rubocop:enable Layout/LineLength
          )
          expect(secrets_repository).to have_received(:update).with(
            account: 'rspec',
            role: 'foo-bar',
            variables: {
              'foo/bar/port' => '1234',
              'foo/bar/url' => 'http://localhost',
              'foo/bar/username' => 'super-user',
              'foo/bar/password' => 'foo-bar'
            }
          )
          expect(subject.success?).to be(true)
        end
      end
      context 'when role is not permitted to set variables' do
        let(:variables) { { port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
        context 'when role is not authorized' do
          let(:secrets_response) { ::FailureResponse.new('Role is unauthorized') }
          it 'applies policy and variables' do
            expect(subject.success?).to be(false)
            expect(policy_loader).to have_received(:call).with(
              # rubocop:disable Layout/LineLength
              default_policy_args.merge(
                target_policy_id: 'rspec:policy:foo',
                policy: "- !policy\n  id: bar\n  annotations:\n    factory: connections/v1/database\n\n  body:\n  - &variables\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n    - !variable ssl-certificate\n    - !variable ssl-key\n    - !variable ssl-ca-certificate\n\n  - !group consumers\n  - !group administrators\n  \n  # consumers can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group consumers\n  \n  # administrators can update (and read and execute, via role grant)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators\n  \n  # administrators has role consumers\n  - !grant\n    member: !group administrators\n    role: !group consumers"
              )
              # rubocop:enable Layout/LineLength
            )
            expect(secrets_repository).to have_received(:update).with(
              account: 'rspec',
              role: 'foo-bar',
              variables: {
                'foo/bar/port' => '1234',
                'foo/bar/url' => 'http://localhost',
                'foo/bar/username' => 'super-user',
                'foo/bar/password' => 'foo-bar'
              }
            )
          end
        end
      end
      context 'when the factory includes default or required to include settings' do
        # rubocop:disable Layout/LineLength
        let(:database_factory) { 'eyJ2ZXJzaW9uIjoidjEiLCJwb2xpY3kiOiJMU0FoY0c5c2FXTjVDaUFnYVdRNklEd2xQU0JwWkNBbFBnb2dJR0Z1Ym05MFlYUnBiMjV6T2dvOEpTQmhibTV2ZEdGMGFXOXVjeTVsWVdOb0lHUnZJSHhyWlhrc0lIWmhiSFZsZkNBdEpUNEtJQ0FnSUR3bFBTQnJaWGtnSlQ0NklEd2xQU0IyWVd4MVpTQWxQZ284SlNCbGJtUWdMU1UrQ2dvZ0lHSnZaSGs2Q2lBZ0xTQW1kbUZ5YVdGaWJHVnpDaUFnSUNBdElDRjJZWEpwWVdKc1pTQjBlWEJsQ2lBZ0lDQXRJQ0YyWVhKcFlXSnNaU0IxY213S0lDQWdJQzBnSVhaaGNtbGhZbXhsSUhCdmNuUUtJQ0FnSUMwZ0lYWmhjbWxoWW14bElIVnpaWEp1WVcxbENpQWdJQ0F0SUNGMllYSnBZV0pzWlNCd1lYTnpkMjl5WkFvZ0lDQWdMU0FoZG1GeWFXRmliR1VnYzNOc0xXTmxjblJwWm1sallYUmxDaUFnSUNBdElDRjJZWEpwWVdKc1pTQnpjMnd0YTJWNUNpQWdJQ0F0SUNGMllYSnBZV0pzWlNCemMyd3RZMkV0WTJWeWRHbG1hV05oZEdVS0NpQWdMU0FoWjNKdmRYQUtJQ0FnSUdsa09pQmpiMjV6ZFcxbGNuTUtJQ0FnSUdGdWJtOTBZWFJwYjI1ek9nb2dJQ0FnSUNCa1pYTmpjbWx3ZEdsdmJqb2dJbEp2YkdWeklIUm9ZWFFnWTJGdUlITmxaU0JoYm1RZ2NtVjBjbWxsZG1VZ1kzSmxaR1Z1ZEdsaGJITXVJZ29nSUFvZ0lDMGdJV2R5YjNWd0NpQWdJQ0JwWkRvZ1lXUnRhVzVwYzNSeVlYUnZjbk1LSUNBZ0lHRnVibTkwWVhScGIyNXpPZ29nSUNBZ0lDQmtaWE5qY21sd2RHbHZiam9nSWxKdmJHVnpJSFJvWVhRZ1kyRnVJSFZ3WkdGMFpTQmpjbVZrWlc1MGFXRnNjeTRpQ2lBZ0NpQWdMU0FoWjNKdmRYQUtJQ0FnSUdsa09pQmphWEpqZFdsMExXSnlaV0ZyWlhJS0lDQWdJR0Z1Ym05MFlYUnBiMjV6T2dvZ0lDQWdJQ0JrWlhOamNtbHdkR2x2YmpvZ1VISnZkbWxrWlhNZ1lTQnRaV05vWVc1cGMyMGdabTl5SUdKeVpXRnJhVzVuSUdGalkyVnpjeUIwYnlCMGFHbHpJR0YxZEdobGJuUnBZMkYwYjNJdUNpQWdJQ0FnSUdWa2FYUmhZbXhsT2lCMGNuVmxDaUFnQ2lBZ0l5QkJiR3h2ZDNNZ0oyTnZibk4xYldWeWN5Y2daM0p2ZFhBZ2RHOGdZbVVnWTNWMElHbHVJR05oYzJVZ2IyWWdZMjl0Y0hKdmJXbHpaUW9nSUMwZ0lXZHlZVzUwQ2lBZ0lDQnRaVzFpWlhJNklDRm5jbTkxY0NCamIyNXpkVzFsY25NS0lDQWdJSEp2YkdVNklDRm5jbTkxY0NCamFYSmpkV2wwTFdKeVpXRnJaWElLSUNBS0lDQWpJRUZrYldsdWFYTjBjbUYwYjNKeklHRnNjMjhnYUdGeklIUm9aU0JqYjI1emRXMWxjbk1nY205c1pRb2dJQzBnSVdkeVlXNTBDaUFnSUNCdFpXMWlaWEk2SUNGbmNtOTFjQ0JoWkcxcGJtbHpkSEpoZEc5eWN3b2dJQ0FnY205c1pUb2dJV2R5YjNWd0lHTnZibk4xYldWeWN3b2dJQW9nSUNNZ1EyOXVjM1Z0WlhKeklDaDJhV0VnZEdobElHTnBjbU4xYVhRdFluSmxZV3RsY2lCbmNtOTFjQ2tnWTJGdUlISmxZV1FnWVc1a0lHVjRaV04xZEdVS0lDQXRJQ0Z3WlhKdGFYUUtJQ0FnSUhKbGMyOTFjbU5sT2lBcWRtRnlhV0ZpYkdWekNpQWdJQ0J3Y21sMmFXeGxaMlZ6T2lCYklISmxZV1FzSUdWNFpXTjFkR1VnWFFvZ0lDQWdjbTlzWlRvZ0lXZHliM1Z3SUdOcGNtTjFhWFF0WW5KbFlXdGxjZ29nSUFvZ0lDTWdRV1J0YVc1cGMzUnlZWFJ2Y25NZ1kyRnVJSFZ3WkdGMFpTQW9kR2hsZVNCb1lYWmxJSEpsWVdRZ1lXNWtJR1Y0WldOMWRHVWdkbWxoSUhSb1pTQmpiMjV6ZFcxbGNuTWdaM0p2ZFhBcENpQWdMU0FoY0dWeWJXbDBDaUFnSUNCeVpYTnZkWEpqWlRvZ0tuWmhjbWxoWW14bGN3b2dJQ0FnY0hKcGRtbHNaV2RsY3pvZ1d5QjFjR1JoZEdVZ1hRb2dJQ0FnY205c1pUb2dJV2R5YjNWd0lHRmtiV2x1YVhOMGNtRjBiM0p6IiwicG9saWN5X2JyYW5jaCI6Ilx1MDAzYyU9IGJyYW5jaCAlXHUwMDNlIiwic2NoZW1hIjp7IiRzY2hlbWEiOiJodHRwOi8vanNvbi1zY2hlbWEub3JnL2RyYWZ0LTA2L3NjaGVtYSMiLCJ0aXRsZSI6IkRhdGFiYXNlIENvbm5lY3Rpb24gVGVtcGxhdGUiLCJkZXNjcmlwdGlvbiI6IkFsbCBpbmZvcm1hdGlvbiBmb3IgY29ubmVjdGluZyB0byBhIGRhdGFiYXNlIiwidHlwZSI6Im9iamVjdCIsInByb3BlcnRpZXMiOnsiaWQiOnsiZGVzY3JpcHRpb24iOiJSZXNvdXJjZSBJZGVudGlmaWVyIiwidHlwZSI6InN0cmluZyJ9LCJhbm5vdGF0aW9ucyI6eyJkZXNjcmlwdGlvbiI6IkFkZGl0aW9uYWwgYW5ub3RhdGlvbnMiLCJ0eXBlIjoib2JqZWN0In0sImJyYW5jaCI6eyJkZXNjcmlwdGlvbiI6IlBvbGljeSBicmFuY2ggdG8gbG9hZCB0aGlzIHJlc291cmNlIGludG8iLCJ0eXBlIjoic3RyaW5nIn0sInZhcmlhYmxlcyI6eyJ0eXBlIjoib2JqZWN0IiwicHJvcGVydGllcyI6eyJ0eXBlIjp7ImRlc2NyaXB0aW9uIjoiRGF0YWJhc2UgVHlwZSIsInR5cGUiOiJzdHJpbmciLCJkZWZhdWx0Ijoic3Fsc2VydmVyIiwiZW51bSI6WyJzcWxzZXJ2ZXIiLCJwb3N0Z3Jlc3FsIiwibXlzcWwiLCJvcmFjbGUiLCJkYjIiLCJzcWxpdGUiXX0sInVybCI6eyJkZXNjcmlwdGlvbiI6IkRhdGFiYXNlIFVSTCIsInR5cGUiOiJzdHJpbmcifSwicG9ydCI6eyJkZXNjcmlwdGlvbiI6IkRhdGFiYXNlIFBvcnQiLCJ0eXBlIjoic3RyaW5nIn0sInVzZXJuYW1lIjp7ImRlc2NyaXB0aW9uIjoiRGF0YWJhc2UgVXNlcm5hbWUiLCJ0eXBlIjoic3RyaW5nIn0sInBhc3N3b3JkIjp7ImRlc2NyaXB0aW9uIjoiRGF0YWJhc2UgUGFzc3dvcmQiLCJ0eXBlIjoic3RyaW5nIn0sInNzbC1jZXJ0aWZpY2F0ZSI6eyJkZXNjcmlwdGlvbiI6IkNsaWVudCBTU0wgQ2VydGlmaWNhdGUiLCJ0eXBlIjoic3RyaW5nIn0sInNzbC1rZXkiOnsiZGVzY3JpcHRpb24iOiJDbGllbnQgU1NMIEtleSIsInR5cGUiOiJzdHJpbmcifSwic3NsLWNhLWNlcnRpZmljYXRlIjp7ImRlc2NyaXB0aW9uIjoiQ0EgUm9vdCBDZXJ0aWZpY2F0ZSIsInR5cGUiOiJzdHJpbmcifX0sInJlcXVpcmVkIjpbInR5cGUiLCJ1cmwiLCJwb3J0IiwidXNlcm5hbWUiLCJwYXNzd29yZCJdfX0sInJlcXVpcmVkIjpbImJyYW5jaCIsImlkIiwidmFyaWFibGVzIl19fQ==' }
        # rubocop:enable Layout/LineLength
        context 'when the request body variable includes an acceptable value' do
          context 'when the factory includes variables with default values' do
            context 'when the request body includes a value for the default' do
              let(:variables) { { type: 'mysql', port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
              it 'submits the policy with the provided values' do
                expect(subject.success?).to be(true)
                expect(policy_loader).to have_received(:call).with(
                  # rubocop:disable Layout/LineLength
                  default_policy_args.merge(
                    target_policy_id: 'rspec:policy:foo',
                    policy: "- !policy\n  id: bar\n  annotations:\n    factory: connections/v1/database\n\n  body:\n  - &variables\n    - !variable type\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n    - !variable ssl-certificate\n    - !variable ssl-key\n    - !variable ssl-ca-certificate\n\n  - !group\n    id: consumers\n    annotations:\n      description: \"Roles that can see and retrieve credentials.\"\n  \n  - !group\n    id: administrators\n    annotations:\n      description: \"Roles that can update credentials.\"\n  \n  - !group\n    id: circuit-breaker\n    annotations:\n      description: Provides a mechanism for breaking access to this authenticator.\n      editable: true\n  \n  # Allows 'consumers' group to be cut in case of compromise\n  - !grant\n    member: !group consumers\n    role: !group circuit-breaker\n  \n  # Administrators also has the consumers role\n  - !grant\n    member: !group administrators\n    role: !group consumers\n  \n  # Consumers (via the circuit-breaker group) can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group circuit-breaker\n  \n  # Administrators can update (they have read and execute via the consumers group)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators"
                  )
                  # rubocop:enable Layout/LineLength
                )
                expect(secrets_repository).to have_received(:update).with(
                  account: 'rspec',
                  role: 'foo-bar',
                  variables: {
                    'foo/bar/port' => '1234',
                    'foo/bar/url' => 'http://localhost',
                    'foo/bar/username' => 'super-user',
                    'foo/bar/password' => 'foo-bar',
                    'foo/bar/type' => 'mysql'
                  }
                )
              end
            end
            context 'when the request body does not include a value for an input with a default' do
              let(:variables) { { port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
              it 'submits the policy with the provided values' do
                expect(subject.success?).to be(true)
                expect(policy_loader).to have_received(:call).with(
                  # rubocop:disable Layout/LineLength
                  default_policy_args.merge(
                    target_policy_id: 'rspec:policy:foo',
                    policy: "- !policy\n  id: bar\n  annotations:\n    factory: connections/v1/database\n\n  body:\n  - &variables\n    - !variable type\n    - !variable url\n    - !variable port\n    - !variable username\n    - !variable password\n    - !variable ssl-certificate\n    - !variable ssl-key\n    - !variable ssl-ca-certificate\n\n  - !group\n    id: consumers\n    annotations:\n      description: \"Roles that can see and retrieve credentials.\"\n  \n  - !group\n    id: administrators\n    annotations:\n      description: \"Roles that can update credentials.\"\n  \n  - !group\n    id: circuit-breaker\n    annotations:\n      description: Provides a mechanism for breaking access to this authenticator.\n      editable: true\n  \n  # Allows 'consumers' group to be cut in case of compromise\n  - !grant\n    member: !group consumers\n    role: !group circuit-breaker\n  \n  # Administrators also has the consumers role\n  - !grant\n    member: !group administrators\n    role: !group consumers\n  \n  # Consumers (via the circuit-breaker group) can read and execute\n  - !permit\n    resource: *variables\n    privileges: [ read, execute ]\n    role: !group circuit-breaker\n  \n  # Administrators can update (they have read and execute via the consumers group)\n  - !permit\n    resource: *variables\n    privileges: [ update ]\n    role: !group administrators"
                  )
                  # rubocop:enable Layout/LineLength
                )
                expect(secrets_repository).to have_received(:update).with(
                  account: 'rspec',
                  role: 'foo-bar',
                  variables: {
                    'foo/bar/port' => '1234',
                    'foo/bar/url' => 'http://localhost',
                    'foo/bar/username' => 'super-user',
                    'foo/bar/password' => 'foo-bar',
                    'foo/bar/type' => 'sqlserver'
                  }
                )
              end
            end
          end
        end
        context 'when the request body does not include a value from the enumeration' do
          let(:variables) { { type: 'foo-bar', port: '1234', url: 'http://localhost', username: 'super-user', password: 'foo-bar' } }
          it 'returns an error response' do
            expect(subject.success?).to be(false)
            expect(subject.message).to eq([{ message: "Value must be one of: 'sqlserver', 'postgresql', 'mysql', 'oracle', 'db2', 'sqlite'", key: 'variables/type' }])
            expect(subject.status).to eq(:bad_request)
          end
        end
      end
    end
  end
end
