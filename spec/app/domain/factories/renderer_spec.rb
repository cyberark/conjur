# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(Factories::Renderer) do
  subject { Factories::Renderer.new }
  describe '.render' do
    context 'when template is valid' do
      let(:template) do
        <<~TEMPLATE
          - !policy
            id: <%= id %>
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
        it 'returns an error' do
          response = subject.render(template: template, variables: {})
          expect(response.success?).to be_falsey
          expect(response.message).to eq("Required template variable 'id' is missing")
        end
      end
      context 'when variable is nil' do
        it 'successfully renders template' do
          response = subject.render(template: template, variables: { id: nil })
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
          it 'successfully renders template' do
            response = subject.render(template: template, variables: { id: %w[foo bar] })
            expect(response.success?).to be_truthy
            expect(response.result).to eq("- !policy\n  id: [\"foo\", \"bar\"]\n")
          end
        end
      end
    end
    context 'when template is invalid' do
      context 'when there is not ERB closing tag' do
        let(:template) do
          <<~TEMPLATE
            - !policy
              id: <%= id
              bar: baz
          TEMPLATE
        end
        it 'the result is successful, does not perform substitution, and does not include the opening tag' do
          response = subject.render(template: template, variables: { id: 'foo' })
          expect(response.success?).to be_truthy
          expect(response.result).to eq("- !policy\n  id:  id\n  bar: baz\n")
        end
      end
      context 'when the template is missing an ERB opening tag' do
        let(:template) do
          <<~TEMPLATE
            - !policy
              id:  id %>
              bar: baz
          TEMPLATE
        end
        it 'the result is successful, does not perform substitution, and includes the closing tag' do
          response = subject.render(template: template, variables: { id: 'foo' })
          expect(response.success?).to be_truthy
          expect(response.result).to eq("- !policy\n  id:  id %>\n  bar: baz\n")
        end
      end
    end
  end
end
