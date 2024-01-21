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
      current_user.kind == "host" &&
        [resource_id].concat(get_variable_ids).any?{|v| v&.start_with?("#{get_account}:variable:data/vault")}
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
        Secret.create(resource_id: get_pcloud_fetch_secret_name, value: Time.now.to_s)
      end
      @@is_pcloud_fetched = true
    end

    def get_account
      account || StaticAccount.account
    end

    def get_variable_ids
      variable_ids
    rescue
      []
    end
  end

  def get_pcloud_fetch_secret_name
    "#{get_account}:variable:#{PCLOUD_ACCESS_SECRET}"
  end
end
