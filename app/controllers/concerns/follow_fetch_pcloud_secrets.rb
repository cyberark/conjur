# frozen_string_literal: true

module FollowFetchPcloudSecrets
  extend ActiveSupport::Concern

  included do
    before_action :check_first_pcloud_fetch, only: [:show, :batch]
    def check_first_pcloud_fetch
      if relevant_call? && !first_fetch_set?
        set_first_fetch
      end
      if first_fetch_set?
        # Remove the before_action for subsequent calls
        self.class.skip_before_action :check_first_pcloud_fetch, only: [:show, :batch]
      end
    end

    def self.set_pcloud_access(value)
      @@is_pcloud_fetched = value
    end

    private
    def relevant_call?
      if action_name == "batch"
        action_variables_ids = variable_ids
      else
        action_variables_ids = [resource_id]
      end
      result = current_user.kind == "host" &&
        action_variables_ids.any?{|v| v&.start_with?("#{get_account}:variable:data/vault")}
      result
    end

    PCLOUD_ACCESS_SECRET = 'internal/telemetry/first_pcloud_fetch'

    def first_fetch_set?
      if !defined?(@@is_pcloud_fetched) || @@is_pcloud_fetched.nil?
        @@is_pcloud_fetched = !Resource[resource_id: get_pcloud_fetch_secret_name]&.secret.nil?
      end
      @@is_pcloud_fetched
    end

    def set_first_fetch
      if Resource[resource_id: get_pcloud_fetch_secret_name] && Secret[resource_id: get_pcloud_fetch_secret_name].nil?
        ::DB::Service::SecretService.instance.secret_value_change(get_pcloud_fetch_secret_name, Time.now.to_s)
        @@is_pcloud_fetched = true
      end
    end

    def get_account
      account || StaticAccount.account
    end
  end

  def get_pcloud_fetch_secret_name
    "#{get_account}:variable:#{PCLOUD_ACCESS_SECRET}"
  end
end
