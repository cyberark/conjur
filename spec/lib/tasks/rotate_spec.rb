require 'spec_helper'
Rails.application.load_tasks
require 'support/slosilo_helper'

describe "rotate:slosilo" do
  id = -> (account, type) { return "authn:#{account}:#{type}" }
  before(:context) do
    init_slosilo_keys("rspec")
    unless ActivityLog["last_slosilo_update"]
      record = ActivityLog.new
      record.activity_id = "last_slosilo_update"
      record.save
    end
    #ActivityLog["last_slosilo_update"] || ActivityLog.create(activity_id: "last_slosilo_update")
  end

  context "rotate key rake" do
    it "rotate key when last time was slosilo_rotation_interval hours ago" do
      ActivityLog["last_slosilo_update"].update({ timestamp: Time.now - Rails.application.config.conjur_config.slosilo_rotation_interval.hours - 1.hours })
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
      ActivityLog["last_slosilo_update"].update({ timestamp:  Time.now - Rails.application.config.conjur_config.slosilo_rotation_interval.hours + 1.hours })
      Slosilo["#{id.call("rspec", "host")}:previous"] ||= Slosilo::Key.new
      Slosilo["#{id.call("rspec", "user")}:previous"] ||= Slosilo::Key.new

      host_key = Slosilo["#{id.call("rspec", "host")}:current"]
      user_key = Slosilo["#{id.call("rspec", "user")}:current"]
      last_timestamp = ActivityLog["last_slosilo_update"].timestamp
      Rake::Task["rotate:slosilo"].execute(account: "rspec")
      host_key_prev = Slosilo["#{id.call("rspec", "host")}:previous"]
      user_key_prev = Slosilo["#{id.call("rspec", "user")}:previous"]
      expect(host_key.fingerprint).to_not eq(host_key_prev.fingerprint)
      expect(user_key.fingerprint).to_not eq(user_key_prev.fingerprint)
      expect(host_key.key.to_der).to_not eq(host_key_prev.key.to_der)
      expect(user_key.key.to_der).to_not eq(user_key_prev.key.to_der)
      expect(ActivityLog["last_slosilo_update"].timestamp).to eq(last_timestamp)
    end
  end

  # context "test" do
  #   it "test2" do
  #     thread1 = Thread.new do
  #       # Code for the first thread
  #       Sequel::Model.db.transaction do
  #         puts "Thread 1 is running"
  #         ActivityLog["last_slosilo_update"].lock!
  #         sleep(10)
  #         puts "Thread 1 execution complete"
  #       end
  #     end
  #
  #     # Create the second thread
  #     thread2 = Thread.new do
  #       # Code for the second thread
  #       begin
  #         Sequel::Model.db.transaction do
  #           puts "Thread 2 is running"
  #           ActivityLog["last_slosilo_update"].lock!
  #           puts "Thread 2 execution complete"
  #         end
  #       rescue
  #         puts "error!!!"
  #       end
  #     end
  #
  #     # Wait for both threads to finish
  #     thread1.join
  #     thread2.join
  #   end
  # end

  # context "rotate key is triggered every 24 hours" do
  #   it "set time to 25 hours from now" do
  #     host_key = Slosilo["#{id.call("rspec", "host")}:current"]
  #     time_tomorrow = Time.now + 1.day + 1.hours
  #     time_tomorrow_noon = Time.new(time_tomorrow.year, time_tomorrow.month, time_tomorrow.day, 0, 0, 0)
  #     Timecop.freeze(time_tomorrow_noon) do
  #       sleep(10)
  #       host_key_prev = Slosilo["#{id.call("rspec", "host")}:previous"]
  #       # puts "prev is: #{host_key_prev}"
  #       expect(host_key.fingerprint).to eq(host_key_prev.fingerprint)
  #     end
  #     Timecop.return
  #   end
  # end
end