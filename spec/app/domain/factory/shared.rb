require 'json_schemer'

RSpec.shared_context('factory schema', shared_context: :metadata) do
  context 'factory schema' do
    let(:data) { JSON.parse(Base64.decode64(subject.data)) }
    let(:schema) { data['schema'] }

    it 'includes policy, policy_namespace, and schema' do
      data_keys = data.keys.sort
      expect(data_keys).to eq(%w[policy policy_namespace schema])
    end

    context 'JSON schema is valid' do
      it 'successfully validates schema' do
        expect { JSONSchemer.schema(schema) }.not_to raise_error
      end
    end

    context 'schema defines all available properties' do
      it 'includes the property: "id"' do
        expect(schema['properties'].keys.sort).to eq(available_properties)
      end
    end

    context 'schema defines all required properties' do
      it 'requires "id"' do
        expect(schema['required'].sort).to eq(required_properties)
      end
    end
  end
end

RSpec.shared_context('factory schema with variables', shared_context: :metadata) do
  context 'factory schema with variables' do
    let(:data) { JSON.parse(Base64.decode64(subject.data)) }
    let(:schema) { data['schema']['properties']['variables'] }

    context 'schema defines all available variables' do
      it 'includes the available variable fields' do
        expect(schema['properties'].keys.sort).to eq(available_variables)
      end
    end

    context 'schema defines all required variables' do
      it 'defines the required variables' do
        expect(schema['required'].sort).to eq(required_variables)
      end
    end
  end
end

RSpec.shared_context('policy template', shared_context: :metadata) do
  context 'policy template' do
    let(:data) { JSON.parse(Base64.decode64(subject.data)) }
    let(:policy_template) { Base64.decode64(data['policy']) }

    context 'it includes all properties as variables' do
      it 'includes relevant variables' do
        (available_properties + required_properties - ['variables']).uniq.each do |property|
          expect(policy_template).to include("<%= #{property} %>")
        end
      end
    end
  end
end


RSpec.configure do |rspec|
  rspec.include_context('factory schema', include_shared: true)
  rspec.include_context('factory schema with variables', include_shared: true)
  rspec.include_context('policy template', include_shared: true)
end
