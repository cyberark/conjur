require 'spec_helper'
Rails.application.load_tasks
require 'support/slosilo_helper'

describe "rotate:slosilo" do
  id = -> (account, type) { return "authn:#{account}:#{type}" }
  before(:context) do
    init_slosilo_keys("rspec")
    ActivityLog["last_slosilo_update"] || ActivityLog.create(id: "last_slosilo_update", timestamp: 100.years.ago)
  end

  before(:each) do
    Rails.cache.clear
  end

  context "rotate key rake" do
    it "rotate key when last time was more then slosilo_rotation_interval hours ago" do
      ActivityLog["last_slosilo_update"].update({ timestamp: Time.now - Rails.application.config.conjur_config.slosilo_rotation_interval.hours - 1.hours })
      expect(Rails.cache).to receive(:delete).twice
      expect(Rails.cache).to receive(:read).exactly(7).times
      expect(Rails.cache).to receive(:write).exactly(15).times
      host_key = Slosilo["#{id.call("rspec", "host")}:current"]
      user_key = Slosilo["#{id.call("rspec", "user")}:current"]
      last_timestamp = ActivityLog["last_slosilo_update"].timestamp
      Rake::Task["rotate:slosilo"].execute(account: "rspec")
      host_key_prev = Slosilo["#{id.call("rspec", "host")}:previous"]
      user_key_prev = Slosilo["#{id.call("rspec", "user")}:previous"]
      expect(host_key.fingerprint).to eq(host_key_prev.fingerprint)
      expect(user_key.fingerprint).to eq(user_key_prev.fingerprint)
      expect(host_key.key.to_der).to eq(host_key_prev.key.to_der)
      expect(user_key.key.to_der).to eq(user_key_prev.key.to_der)
      expect(ActivityLog["last_slosilo_update"].timestamp).to be > last_timestamp
    end

    it "do not rotate key when last time was less then slosilo_rotation_interval hours ago" do
      ActivityLog["last_slosilo_update"].update({timestamp: Time.now - Rails.application.config.conjur_config.slosilo_rotation_interval.hours + 1.hours })
      Slosilo["#{id.call("rspec", "host")}:previous"] ||= Slosilo::Key.new
      Slosilo["#{id.call("rspec", "user")}:previous"] ||= Slosilo::Key.new
      host_key = Slosilo["#{id.call("rspec", "host")}:current"]
      user_key = Slosilo["#{id.call("rspec", "user")}:current"]
      host_redis_value = Rails.cache.read("slosilo/#{id.call("rspec", "host")}:current")
      expect(host_redis_value).to be
      last_timestamp = ActivityLog["last_slosilo_update"].timestamp
      Rake::Task["rotate:slosilo"].execute(account: "rspec")
      host_key_prev = Slosilo["#{id.call("rspec", "host")}:previous"]
      user_key_prev = Slosilo["#{id.call("rspec", "user")}:previous"]
      host_redis_value_previous = Rails.cache.read("slosilo/#{id.call("rspec", "host")}:previous")
      expect(host_redis_value_previous).to be
      expect(host_redis_value).to_not eq(host_redis_value_previous)
      expect(host_key.fingerprint).to_not eq(host_key_prev.fingerprint)
      expect(user_key.fingerprint).to_not eq(user_key_prev.fingerprint)
      expect(host_key.key.to_der).to_not eq(host_key_prev.key.to_der)
      expect(user_key.key.to_der).to_not eq(user_key_prev.key.to_der)
      expect(ActivityLog["last_slosilo_update"].timestamp).to eq(last_timestamp)
    end
  end
end
