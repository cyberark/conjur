require 'spec_helper'

describe Commands::Policy::Parse do

  testacct = "rspec"

  policy_root = "rspec:policy:root"
  policy_nonroot = "rspec:policy:cucumber"

  testowner = "root:user:alice"

  name_valid = "valid_policy.yml"
  text_valid = <<~POLICY
  - !user
    id: Eve
                  POLICY

  name_invalid = "invalid_policy.yml"
  text_invalid = <<~POLICY
  - !user
    kid: Eve
                    POLICY

  parse_root_valid =
    Commands::Policy::Parse.new.call(account: testacct,
                                     policy_id: policy_root,
                                     owner_id: testowner,
                                     policy_text: text_valid,
                                     policy_filename: name_valid,
                                     root_policy: true)

  parse_root_invalid =
    Commands::Policy::Parse.new.call(account: testacct,
                                     policy_id: policy_root,
                                     owner_id: testowner,
                                     policy_text: text_invalid,
                                     policy_filename: name_invalid,
                                     root_policy: true)

  parse_nonroot_valid =
    Commands::Policy::Parse.new.call(account: testacct,
                                     policy_id: policy_nonroot,
                                     owner_id: testowner,
                                     policy_text: text_valid,
                                     policy_filename: name_valid,
                                     root_policy: false)

  parse_nonroot_invalid =
    Commands::Policy::Parse.new.call(account: testacct,
                                     policy_id: policy_nonroot,
                                     owner_id: testowner,
                                     policy_text: text_invalid,
                                     policy_filename: name_invalid,
                                     root_policy: false)

  context 'with a valid root policy' do
    it 'it returns records and reports no errors' do
      aggregate_failures "multiple ways for parse to fail" do
        expect(parse_root_valid.records).not_to match_array([])
        expect(parse_root_valid.error).to be_nil
      end
    end
  end

  context 'with a valid non-root policy' do
    it 'it returns records and reports no errors' do
      aggregate_failures "multiple ways for parse to fail" do
        expect(parse_nonroot_valid.records).not_to match_array([])
        expect(parse_nonroot_valid.error).to be_nil
      end
    end
  end

  context 'with an invalid root policy' do
    it 'it returns no records and reports errors' do
      aggregate_failures "multiple ways for parse to fail" do
        expect(parse_root_invalid.records).to match_array([])
        expect(parse_root_invalid.error).to match(/No such attribute/)
      end
    end
  end

  context 'with an invalid non-root policy' do
    it 'it returns no records and reports errors' do
      aggregate_failures "multiple ways for parse to fail" do
        expect(parse_nonroot_invalid.records).to match_array([])
        expect(parse_nonroot_invalid.error).to match(/No such attribute/)
      end
    end
  end

end
