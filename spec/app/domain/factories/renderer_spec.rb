# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Factories::Renderer) do
  subject { Factories::Renderer.new }
  describe '.render' do
    context 'when template is valid' do
      let(:template) do
        <<~TEMPLATE
          - !policy
            id: {{ id }}
        TEMPLATE
      end
      context 'when all variables are present' do
        it 'successfully renders template' do
          response = subject.render(template: template, variables: { id: 'foo' })
          expect(response.success?).to be_truthy
          expect(response.result).to eq("- !policy\n  id: foo\n")
        end
      end
      context 'when variables are missing' do
        it 'template is rendered with missing variables as empty strings' do
          response = subject.render(template: template, variables: {})
          expect(response.success?).to be_truthy
          expect(response.result).to eq("- !policy\n  id: \n")
        end
      end
      context 'when extra variables are present' do
        it 'successfully renders template' do
          response = subject.render(template: template, variables: { id: 'foo', bar: 'baz' })
          expect(response.success?).to be_truthy
          expect(response.result).to eq("- !policy\n  id: foo\n")
        end
      end
      context 'when variables are not strings' do
        context 'when variable is an integer' do
          it 'successfully renders template' do
            response = subject.render(template: template, variables: { id: 1 })
            expect(response.success?).to be_truthy
            expect(response.result).to eq("- !policy\n  id: 1\n")
          end
        end
        context 'when variable is a boolean' do
          it 'successfully renders template' do
            response = subject.render(template: template, variables: { id: false })
            expect(response.success?).to be_truthy
            expect(response.result).to eq("- !policy\n  id: false\n")
          end
        end
        context 'when variable is an array' do
          it 'the array is rendered as an escaped array' do
            response = subject.render(template: template, variables: { id: %w[foo bar] })
            expect(response.success?).to be_truthy
            expect(response.result).to eq("- !policy\n  id: [&quot;foo&quot;, &quot;bar&quot;]\n")
          end
        end
      end
      context 'when template includes optional values' do
        let(:template) do
          <<~TEMPLATE
            - !policy
              id: {{ id }}
            {{#owner}}
              owner: {{ owner }}
            {{/owner}}
          TEMPLATE
        end
        context 'when optional value is present' do
          it 'successfully renders template' do
            response = subject.render(template: template, variables: { id: 'foo', owner: 'bar' })
            expect(response.success?).to be_truthy
            expect(response.result).to eq("- !policy\n  id: foo\n  owner: bar\n")
          end
        end
        context 'when optional value is missing' do
          it 'successfully renders template' do
            response = subject.render(template: template, variables: { id: 'foo', owner: nil })
            expect(response.success?).to be_truthy
            expect(response.result).to eq("- !policy\n  id: foo\n")
          end
        end
        context 'when optional value is an empty string' do
          it 'successfully renders template' do
            response = subject.render(template: template, variables: { id: 'foo', owner: '' })
            expect(response.success?).to be_truthy
            expect(response.result).to eq("- !policy\n  id: foo\n")
          end
        end
      end
      context 'when the template includes nil values' do
        let(:template) do
          <<~TEMPLATE
            - !policy
              id: {{ id }}
            {{#owner}}
              owner: {{ owner }}
            {{/owner}}
          TEMPLATE
        end
        it 'successfully renders template' do
          response = subject.render(template: template, variables: { id: 'foo', owner: nil })
          expect(response.success?).to be_truthy
          expect(response.result).to eq("- !policy\n  id: foo\n")
        end
      end
      context 'when template includes a hash' do
        let(:template) do
          <<~TEMPLATE
            - !policy
              id: {{ id }}
              annotations:
              {{#annotations}}
                {{ key }}: {{ value }}
              {{/annotations}}
          TEMPLATE
        end
        it 'successfully renders template' do
          response = subject.render(template: template, variables: { id: 'foo', annotations: { foo: 'bar' } })
          expect(response.success?).to be_truthy
          expect(response.result).to eq("- !policy\n  id: foo\n  annotations:\n    foo: bar\n")
        end
        context 'when hash includes multiple key value pairs' do
          it 'successfully renders template' do
            response = subject.render(template: template, variables: { id: 'foo', annotations: { foo: 'bar', baz: 'qux' } })
            expect(response.success?).to be_truthy
            expect(response.result).to eq("- !policy\n  id: foo\n  annotations:\n    foo: bar\n    baz: qux\n")
          end
        end
      end
    end
    context 'when template is invalid' do
      context 'when there is no closing tag' do
        let(:template) do
          <<~TEMPLATE
            - !policy
              id: {{ id
              bar: baz
          TEMPLATE
        end
        it 'the result is unsuccessful' do
          response = subject.render(template: template, variables: { id: 'foo' })
          expect(response.success?).to be_falsey
          expect(response.message).to eq('Template includes invalid syntax')
        end
      end
      context 'when the template is missing a an opening tag' do
        let(:template) do
          <<~TEMPLATE
            - !policy
              id:  id }}
              bar: baz
          TEMPLATE
        end
        it 'the result is unsuccessful' do
          response = subject.render(template: template, variables: { id: 'foo' })
          expect(response.success?).to be_falsey
          expect(response.message).to eq('Template includes invalid syntax')
        end
      end
    end
    context 'when template includes arbitrary ruby code' do
      let(:template) do
        <<~TEMPLATE
          - !policy
            id: {{ raise 'foo' }}
        TEMPLATE
      end
      it 'does not execute the ruby code' do
        response = subject.render(template: template, variables: {})
        expect(response.success?).to be_falsey
        expect(response.message).to eq('Template includes invalid syntax')
      end
    end
  end
end
