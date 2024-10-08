# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(DB::Repository::PolicyRepository) do
  subject do 
    DB::Repository::PolicyRepository.new(
      db: mock_db
    )
  end

  # For the public method tests
  let(:mock_db) { class_double('Sequel::Model.db') }
  let(:mock_dataset) { instance_double('Sequel::Dataset') }
  let(:query_result) { [] }
  let(:desired_result) do
    {
      annotations: [],
      credentials: [],
      permissions: [],
      resources: [],
      role_memberships: [],
      roles: []
    }
  end
  # For the private method tests
  let(:mock_model) { double('model') }
  let(:table_name) { :credentials }
  let(:table_columns) { %i[role_id client_id api_key encrypted_hash expiration restricted_to] }
  let(:table_primary_keys) { %i[role_id] }
  let(:terminate) { false }
  let(:schema_a) { 'policy_loader_before_abcdefgh' }
  let(:schema_b) { 'public' }

  describe '.find_created_elements' do
    context 'when given valid parameters' do
      let(:diff_schema_name) { "policy_loader_before_abcdefg" }

      before do
        allow(mock_db).to receive(:fetch).and_return(mock_dataset)
        allow(mock_db).to receive(:execute).and_return(nil)
        allow(mock_dataset).to receive(:all).and_return(query_result)
      end

      it 'returns success' do
        response = subject.find_created_elements(diff_schema_name: diff_schema_name)
        expect(response.success?).to eq(true)
        expect(response.result).to be_an_instance_of(DB::Repository::DataObjects::DiffElements)
        expect(response.result.all_elements).to match(desired_result)
      end
    end
  end

  describe '.find_deleted_elements' do
    context 'when given valid parameters' do
      let(:diff_schema_name) { "policy_loader_before_abcdefg" }

      before do
        allow(mock_db).to receive(:fetch).and_return(mock_dataset)
        allow(mock_db).to receive(:execute).and_return(nil)
        allow(mock_dataset).to receive(:all).and_return(query_result)
      end

      it 'returns success' do
        response = subject.find_deleted_elements(diff_schema_name: diff_schema_name)
        expect(response.success?).to eq(true)
        expect(response.result).to be_an_instance_of(DB::Repository::DataObjects::DiffElements)
        expect(response.result.all_elements).to match(desired_result)
      end
    end
  end

  describe '.find_original_elements' do
    context 'when given valid parameters' do
      let(:diff_schema_name) { "policy_loader_before_abcdefg" }

      before do
        allow(mock_db).to receive(:fetch).and_return(mock_dataset)
        allow(mock_db).to receive(:execute).and_return(nil)
        allow(mock_dataset).to receive(:all).and_return(query_result)
      end

      it 'returns success' do
        response = subject.find_original_elements(diff_schema_name: diff_schema_name)
        expect(response.success?).to eq(true)
        expect(response.result).to be_an_instance_of(DB::Repository::DataObjects::DiffElements)
        expect(response.result.all_elements).to match(desired_result)
      end
    end
  end

  # Below, private methods that generate SQL strings. We won't test every query
  # here but rather, we verify that the query string is generated 
  # given some inputs.
  describe '.generate_unique_to_b_query' do
    context 'when given schema a and b' do
      let(:desired_result) do
        <<~SQL.chomp
          SELECT role_id, client_id, restricted_to FROM public.credentials
          EXCEPT
          SELECT role_id, client_id, restricted_to FROM policy_loader_before_abcdefgh.credentials
          ORDER BY role_id
        SQL
      end

      it 'generates the correct SQL query' do
        query = subject.send(
          :generate_unique_to_b_query,
          table_name: table_name,
          schema_a: schema_a,
          schema_b: schema_b,
          terminate: terminate
        )
        expect(query).to eq(desired_result)
      end

      context 'when terminate is true' do
        let(:terminate) { true }
        it 'includes the SQL terminator at the end of the query' do
          query = subject.send(
            :generate_unique_to_b_query,
            table_name: table_name,
            schema_a: schema_a,
            schema_b: schema_b,
            terminate: terminate
          )
          expect(query).to eq("#{desired_result};")
        end
      end
    end

    context 'when schema a and b are swapped' do
      let(:schema_a) { 'public' }
      let(:schema_b) { 'policy_loader_before_abcdefgh' }
      let(:desired_result) do
        <<~SQL.chomp
          SELECT role_id, client_id, restricted_to FROM policy_loader_before_abcdefgh.credentials
          EXCEPT
          SELECT role_id, client_id, restricted_to FROM public.credentials
          ORDER BY role_id
        SQL
      end

      it 'generates the correct SQL query' do
        query = subject.send(
          :generate_unique_to_b_query,
          table_name: table_name,
          schema_a: schema_a,
          schema_b: schema_b,
          terminate: terminate
        )
        expect(query).to eq(desired_result)
      end

      context 'when terminate is true' do
        let(:terminate) { true }
  
        it 'includes the SQL terminator at the end of the query' do
          query = subject.send(
            :generate_unique_to_b_query,
            table_name: table_name,
            schema_a: schema_a,
            schema_b: schema_b,
            terminate: terminate
          )
          expect(query).to eq("#{desired_result};")
        end
      end
    end
  end

  describe '.generate_union_queries_for_updated_resources' do
    let(:desired_result) do
      <<~SQL
        SELECT role_id AS resource_id FROM cte_credentials_unique_to_a
        UNION
        SELECT role_id AS resource_id FROM cte_credentials_unique_to_b
      SQL
    end

    it 'generates the correct SQL query' do
      query = subject.send(
        :generate_union_queries_for_updated_resources,
        table_name: table_name
      )
      expect(query).to eq([desired_result])
    end
  end

  describe '.generate_original_elements_for_table_query' do
    context 'when given the permissions table' do
      let(:table_name) { :permissions }
      let(:table_columns) { %i[role_id resource_id privilege policy_id] }
      let(:table_primary_keys) { %i[resource_id role_id privilege] }
      let(:desired_result) do
        <<~SQL
          SELECT DISTINCT a.role_id, a.resource_id, a.privilege, a.policy_id
          FROM policy_loader_before_abcdefgh.permissions a
          JOIN policy_loader_before_abcdefgh.updated_resources b
          ON a.resource_id = b.resource_id OR a.role_id = b.resource_id
          ORDER BY a.resource_id, a.role_id, a.privilege;
        SQL
      end
  
      it 'generates the correct SQL query' do
        query = subject.send(
          :generate_original_elements_for_table_query,
          original_schema: schema_a,
          table_name: table_name,
          columns: table_columns,
          primary_keys: table_primary_keys
        )
        expect(query).to eq(desired_result)
      end
    end
  end

  # Maybe testing the parent method above is enough ()
  describe '.generate_join_statement_for_original_resources' do
  end

  # This method is used to generate a preferred order of columns used in an
  # ORDER BY clause, used when querying the diff.
  describe '.reorder_array'  do
    it 'reorders the array based on the preferred order' do
      array = %w[a b c d]
      preferred_order = %w[c a]
      expected_result = %w[c a b d]
      result = subject.send(:reorder_array, array: array, preferred_order: preferred_order)
      expect(result).to eq(expected_result)
    end

    it 'returns the original array if preferred order is empty' do
      array = %w[a b c d]
      preferred_order = []
      expected_result = %w[a b c d]
      result = subject.send(:reorder_array, array: array, preferred_order: preferred_order)
      expect(result).to eq(expected_result)
    end

    it 'returns the original array if preferred order does not match any elements' do
      array = %w[a b c d]
      preferred_order = %w[x y]
      expected_result = %w[a b c d]
      result = subject.send(:reorder_array, array: array, preferred_order: preferred_order)
      expect(result).to eq(expected_result)
    end

    it 'returns the preferred order if it contains all elements of the array' do
      array = %w[a b c d]
      preferred_order = %w[d c b a]
      expected_result = %w[d c b a]
      result = subject.send(:reorder_array, array: array, preferred_order: preferred_order)
      expect(result).to eq(expected_result)
    end

    it 'handles arrays with duplicate elements' do
      array = %w[a b a c d]
      preferred_order = %w[a c]
      expected_result = %w[a c b d]
      result = subject.send(:reorder_array, array: array, preferred_order: preferred_order)
      expect(result).to eq(expected_result)
    end
  end
end
