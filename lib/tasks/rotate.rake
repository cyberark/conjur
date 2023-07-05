# This rake task is scheduled once in 24 hours.
# It rotates current slosilo key with previous, so token that are signed with previous key can still be validated.

desc "rotate sloislo key"
namespace :rotate do
  task :"slosilo", [:account] => :environment do |t, args|
    account = args[:account] || "conjur"
    id = -> (account, type) { return "authn:#{account}:#{type}" }
    unless Slosilo["#{id.call(account, "host")}:current"] || Slosilo["#{id.call(account, "user")}:current"]
      Rails.logger.info(Errors::Conjur::FailedRotateSlosilo.new("Slosilo keys weren't found in db"))
      abort
    end
    begin
      Sequel::Model.db.transaction do
        last_update = ActivityLog["last_slosilo_update"].lock!
        last_update_time = last_update.timestamp
        # This tasks runs in all Conjur instances, thus, we check if it already run in the last 24 hours.
        if last_update_time < Rails.application.config.conjur_config.slosilo_rotation_interval.hours.ago
          # rotate users key
          rotate_slosilo(id.call(account, "user"))
          # rotate hosts key
          rotate_slosilo(id.call(account, "host"))
          ActivityLog["last_slosilo_update"].update({timestamp: Time.now})
          Rails.logger.info(LogMessages::Conjur::SlosiloRotate.new())
        end
      end
    rescue => e
      # Handle the lock failure
      Rails.logger.info(Errors::Conjur::FailedRotateSlosilo.new(e.message))
    end
  end

  def rotate_slosilo(id)
    prev = Slosilo["#{id}:current"]
    Slosilo["#{id}:current"] = Slosilo::Key.new
    Slosilo["#{id}:previous"] = prev
  end
end
