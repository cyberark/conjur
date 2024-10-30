# frozen_string_literal: true

require 'spec_helper'
require 'audit_spec_helper'

RSpec.describe(DB::Repository::SecretsRepository) do
  let(:rbac) do
    instance_double(RBAC::Permission).tap do |rbac|
      %w[foo bar].each do |variable|
        allow(rbac).to receive(:permitted?).with(privilege: :execute, resource_id: "rspec:variable:foo-bar/testing/#{variable}", role: role).and_return(::SuccessResponse.new(''))
        allow(rbac).to receive(:permitted?).with(privilege: :update, resource_id: "rspec:variable:foo-bar/testing/#{variable}", role: role).and_return(::SuccessResponse.new(''))
      end
      allow(rbac).to receive(:permitted?).with(privilege: :update, resource_id: "rspec:variable:foo-bar/testing/bing", role: role).and_return(::SuccessResponse.new(''))
      allow(rbac).to receive(:permitted?).with(privilege: :update, resource_id: "rspec:variable:foo-bar/testing/baz", role: role).and_return(::FailureResponse.new(''))
    end
  end
  let(:role) { Role['rspec:policy:foo-bar/testing'] }
  let(:log_output) { StringIO.new }
  let(:audit_logger) do
    Audit::Log::SyslogAdapter.new(
      Logger.new(log_output).tap do |logger|
        logger.formatter = Logger::Formatter::RFC5424Formatter
      end
    )
  end
  let(:context) { RequestContext::Context.new(role: role, request_ip: '127.0.0.1') }

  subject do
    described_class.new(
      rbac: rbac,
      audit_logger: audit_logger
    )
  end
  describe '.find_all' do
    context 'when variables are not present' do
      before(:each) do
        ::Role.create(
          role_id: "rspec:policy:foo-bar/testing"
        )
      end
      after(:each) do
        ::Role['rspec:policy:foo-bar/testing'].destroy
      end
      it 'returns an failure response' do
        response = subject.find_all(
          account: 'rspec',
          policy_path: 'foo-bar/testing',
          variables: %w[foo bar],
          context: context
        )

        # No audit messages are logged
        expect(log_output.string).to eq('')

        expect(response.success?).to be(false)
        expect(response.message).to eq("No variable secrets were found")
      end
      context 'when variables are present' do
        before(:each) do
          ::Resource.create(
            resource_id: "rspec:variable:foo-bar/testing/foo",
            owner_id: "rspec:policy:foo-bar/testing"
          )
          ::Resource.create(
            resource_id: "rspec:variable:foo-bar/testing/bar",
            owner_id: "rspec:policy:foo-bar/testing"
          )
          ::Resource.create(
            resource_id: "rspec:variable:foo-bar/testing/baz",
            owner_id: "rspec:policy:foo-bar/testing"
          )
        end
        after(:each) do
          ::Resource['rspec:variable:foo-bar/testing/foo'].destroy
          ::Resource['rspec:variable:foo-bar/testing/bar'].destroy
          ::Resource['rspec:variable:foo-bar/testing/baz'].destroy
        end
        context 'when variable secrets do not have values' do
          it 'returns a hash with empty values' do
            response = subject.find_all(
              account: 'rspec',
              policy_path: 'foo-bar/testing',
              variables: %w[foo bar],
              context: context
            )

            expect_audit(
              result: 'success',
              operation: 'fetch',
              message: 'rspec:policy:foo-bar/testing fetched rspec:variable:foo-bar/testing/foo'
            )
            expect_audit(
              result: 'success',
              operation: 'fetch',
              message: 'rspec:policy:foo-bar/testing fetched rspec:variable:foo-bar/testing/bar'
            )
            expect(response.success?).to be(true)
            expect(response.result).to eq({
              'foo-bar/testing/foo' => nil,
              'foo-bar/testing/bar' => nil
            })
          end
        end
        context 'when variables have secret values' do
          before(:each) do
            ::Secret.create(
              resource_id: "rspec:variable:foo-bar/testing/foo",
              value: 'foo'
            )
            ::Secret.create(
              resource_id: "rspec:variable:foo-bar/testing/bar",
              value: 'bar'
            )
          end
          it 'returns a hash with secret values' do
            response = subject.find_all(
              account: 'rspec',
              policy_path: 'foo-bar/testing',
              variables: %w[foo bar],
              context: context
            )

            expect_audit(
              result: 'success',
              operation: 'fetch',
              message: 'rspec:policy:foo-bar/testing fetched rspec:variable:foo-bar/testing/foo'
            )
            expect_audit(
              result: 'success',
              operation: 'fetch',
              message: 'rspec:policy:foo-bar/testing fetched rspec:variable:foo-bar/testing/bar'
            )
            expect(response.success?).to be(true)
            expect(response.result).to eq({
              'foo-bar/testing/foo' => 'foo',
              'foo-bar/testing/bar' => 'bar'
            })
          end
        end
        context 'when role does not have permission to retrieve variables' do
          context 'when some variables are not permitted' do
            let(:rbac) do
              instance_double(RBAC::Permission).tap do |rbac|
                allow(rbac).to receive(:permitted?).with(privilege: :execute, resource_id: "rspec:variable:foo-bar/testing/foo", role: role).and_return(::SuccessResponse.new(''))
                allow(rbac).to receive(:permitted?).with(privilege: :execute, resource_id: "rspec:variable:foo-bar/testing/bar", role: role).and_return(::FailureResponse.new(''))
              end
            end

            it 'returns a hash with secret values' do
              response = subject.find_all(
                account: 'rspec',
                policy_path: 'foo-bar/testing',
                variables: %w[foo bar],
                context: context
              )

              expect_audit(
                result: 'success',
                operation: 'fetch',
                message: 'rspec:policy:foo-bar/testing fetched rspec:variable:foo-bar/testing/foo'
              )
              expect_audit(
                result: 'failure',
                operation: 'fetch',
                message: 'rspec:policy:foo-bar/testing tried to fetch rspec:variable:foo-bar/testing/bar: Forbidden'
              )
              expect(response.success?).to be(true)
              expect(response.result).to eq({ 'foo-bar/testing/foo' => nil })
            end
          end
          context 'when all variables are not permitted' do
            let(:rbac) do
              instance_double(RBAC::Permission).tap do |rbac|
                %w[foo bar].each do |variable|
                  allow(rbac).to receive(:permitted?).with(privilege: :execute, resource_id: "rspec:variable:foo-bar/testing/#{variable}", role: role).and_return(::FailureResponse.new(''))
                end
              end
            end
            it 'is unsuccessful' do
              response = subject.find_all(
                account: 'rspec',
                policy_path: 'foo-bar/testing',
                variables: %w[foo bar],
                context: context
              )

              expect_audit(
                result: 'failure',
                operation: 'fetch',
                message: 'rspec:policy:foo-bar/testing tried to fetch rspec:variable:foo-bar/testing/foo: Forbidden'
              )
              expect_audit(
                result: 'failure',
                operation: 'fetch',
                message: 'rspec:policy:foo-bar/testing tried to fetch rspec:variable:foo-bar/testing/bar: Forbidden'
              )
              expect(response.success?).to be(false)
              expect(response.message).to eq("No variable secrets were found")
              expect(response.status).to eq(:not_found)
              expect(response.exception).to be_a(Errors::Authorization::InsufficientResourcePrivileges)
              expect(response.exception.message).to eq("CONJ00124E Role 'rspec:policy:foo-bar/testing' has insufficient privileges over the resource 'foo-bar/testing/foo, foo-bar/testing/bar'")
            end
          end
        end
      end
    end
  end

  describe '.update' do
    before(:each) do
      ::Role.create(role_id: "rspec:policy:foo-bar/testing")
      %w[foo bar baz].each do |variable|
        ::Resource.create(
          resource_id: "rspec:variable:foo-bar/testing/#{variable}",
          owner_id: "rspec:policy:foo-bar/testing"
        )
        ::Secret.create(
          resource_id: "rspec:variable:foo-bar/testing/#{variable}",
          value: variable
        )
      end
    end
    after(:each) do
      %w[foo bar baz].each do |variable|
        ::Resource["rspec:variable:foo-bar/testing/#{variable}"].destroy
      end
      ::Role['rspec:policy:foo-bar/testing'].destroy
    end
    context 'when role has permission to update variables' do
      context 'when variables are present' do
        context 'when variable values are present' do
          it 'is successful' do
            response = subject.update(
              account: 'rspec',
              policy_path: 'foo-bar/testing',
              variables: { 'foo' => 'foo-1', 'bar' => 'bar-1' },
              context: context
            )

            expect(response.success?).to be(true)

            %w[foo bar].each do |variable|
              expect_audit(
                result: 'success',
                operation: 'update',
                message: "rspec:policy:foo-bar/testing updated rspec:variable:foo-bar/testing/#{variable}"
              )
              expect(::Resource["rspec:variable:foo-bar/testing/#{variable}"].secret.value).to eq("#{variable}-1")
            end
          end
        end
        context 'when variable values are not present' do
          it 'is unsuccessful and does not change missing values' do
            response = subject.update(
              account: 'rspec',
              policy_path: 'foo-bar/testing',
              variables: { 'foo' => nil, 'bar' => 'bar-1' },
              context: context
            )

            expect_audit(
              result: 'success',
              operation: 'update',
              message: 'rspec:policy:foo-bar/testing updated rspec:variable:foo-bar/testing/bar'
            )
            expect(response.success?).to be(false)

            expect(::Resource["rspec:variable:foo-bar/testing/foo"].secret.value).to eq('foo')
            expect(::Resource["rspec:variable:foo-bar/testing/bar"].secret.value).to eq('bar-1')
          end
        end
      end
      context 'when variable does not exist' do
        it 'is unsuccessful' do
          response = subject.update(
            account: 'rspec',
            policy_path: 'foo-bar/testing',
            variables: { 'foo' => 'foo-1', 'bar' => 'bar-1', 'bing' => 'baz' },
            context: context
          )
          expect_audit(
            result: 'success',
            operation: 'update',
            message: 'rspec:policy:foo-bar/testing updated rspec:variable:foo-bar/testing/foo'
          )
          expect_audit(
            result: 'success',
            operation: 'update',
            message: 'rspec:policy:foo-bar/testing updated rspec:variable:foo-bar/testing/bar'
          )
          expect(response.success?).to be(false)

          expect(::Resource["rspec:variable:foo-bar/testing/foo"].secret.value).to eq('foo-1')
          expect(::Resource["rspec:variable:foo-bar/testing/bar"].secret.value).to eq('bar-1')
        end
      end
      context 'when variables are not present' do
        it 'is unsuccessful' do
          response = subject.update(
            account: 'rspec',
            policy_path: 'foo-bar/testing',
            variables: nil,
            context: context
          )

          expect(response.success?).to be(false)
          expect(response.message).to eq('variables must be a Hash or Array')
          expect(response.exception).to be_a(ArgumentError)

          # No audit messages are logged
          expect(log_output.string).to eq('')

          # Secret values are unchanged
          %w[foo bar].each do |variable|
            expect(::Resource["rspec:variable:foo-bar/testing/#{variable}"].secret.value).to eq(variable)
          end
        end
      end
    end
    context 'when role does not have permission to update variables' do
      it 'is unsuccessful if any variable is not permitted' do
        response = subject.update(
          account: 'rspec',
          policy_path: 'foo-bar/testing',
          variables: { 'foo' => 'foo-1', 'bar' => 'bar-1', 'baz' => 'baz-1' },
          context: context
        )

        expect_audit(
          result: 'success',
          operation: 'update',
          message: 'rspec:policy:foo-bar/testing updated rspec:variable:foo-bar/testing/foo'
        )
        expect_audit(
          result: 'success',
          operation: 'update',
          message: 'rspec:policy:foo-bar/testing updated rspec:variable:foo-bar/testing/bar'
        )
        expect(response.success?).to be(false)
        expect(response.message.reject(&:success?).count).to eq(1)
        expect(response.message.reject(&:success?).first.message).to eq("Role: 'rspec:policy:foo-bar/testing' does not have permission to update variable 'rspec:variable:foo-bar/testing/baz'")

        # Secret values are unchanged
        %w[foo bar].each do |variable|
          expect(::Resource["rspec:variable:foo-bar/testing/#{variable}"].secret.value).to eq("#{variable}-1")
        end
      end
    end
  end
end
