desc "rotate sloislo key"
namespace :rotate do
  task :"slosilo", [:account] => :environment do |t, args|
    account = args[:account] || "conjur"
    id = -> (account, type) { return "authn:#{account}:#{type}" }
    unless Slosilo["#{id.call(account, "host")}:current"] || Slosilo["#{id.call(account, "user")}:current"]
      abort
    end
    puts "here"
    begin
      # puts "here2"
      Sequel::Model.db.transaction do
        last_update = ActivityLog["last_slosilo_update"].lock!
        last_update_time = last_update.timestamp
        if last_update_time < 24.hours.ago
          #   puts "rotated!"
          # rotate users key
          rotate_slosilo(id.call(account, "user"))
          # rotate hosts key
          rotate_slosilo(id.call(account, "host"))
          ActivityLog["last_slosilo_update"].update({timestamp: Time.now})
          Rails.logger.info(LogMessages::Conjur::SlosiloRotate.new())
        end
      end
    rescue
      # Handle the lock failure
      Rails.logger.info(Errors::Conjur::FailedRotateSlosilo.new())
    end
  end

  def rotate_slosilo(id)
    puts "rotated2!"
    #puts "id is: #{id}"
    prev = Slosilo["#{id}:current"]
    Slosilo["#{id}:current"] = Slosilo::Key.new
    Slosilo["#{id}:previous"] = prev
    # model = Sequel::Model(:slosilo_keystore)
    # model.save
    #Slosilo.save
    #puts "id is: #{id}:previous"
    #puts "rotates is #{Slosilo["#{id}:previous"]}"
  end
end
