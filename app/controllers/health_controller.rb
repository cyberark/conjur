# frozen_string_literal: true
class HealthController < ActionController::API

  def health
    if check_db_connection
      head :ok
    else
      head :service_unavailable
    end
    response.headers['Cache-Control'] = 'no-cache, no-store, max-age=0, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'
  end
  def check_db_connection
    begin
      Sequel::Model.db['SELECT 1'].single_value
      return true
    rescue Exception => e
      return false
    end
  end
end