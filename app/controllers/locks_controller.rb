# frozen_string_literal: true

class LocksController < RestController
  # include FindResource
  # include AuthorizeResource
  include BodyParser

  # before_action :current_user

  LOCK_NOT_FOUND = "Lock not found"

  def create
    logger.info("POST /locks/:account started")
    # authorize(:create)

    delete_expired(params[:account])

    current_timestamp = Time.now
    expires_at = current_timestamp + params[:ttl]
    lock = Lock.new(lock_id: params[:id], account: params[:account],
                    owner: params[:owner],
                    modified_at: Sequel::CURRENT_TIMESTAMP,
                    expires_at: expires_at)
    lock.save

    render(json: lock.as_json, status: :created)
    logger.info("POST /locks/:account ended successfully")
  rescue Sequel::UniqueConstraintViolation => e
    logger.error("The lock [#{params[:id]}] already exists")
    raise Exceptions::RecordExists.new("lock", params[:id])
  end

  def get
    logger.info("GET /locks/:account/*identifier started")
    # authorize(:read, resource)

    delete_expired(params[:account])

    lock = get_lock_from_db(params[:account], params[:identifier])
    if lock
      render(json: lock.as_json, status: :ok)
    else
      raise Exceptions::RecordNotFound.new(params[:identifier], message: LOCK_NOT_FOUND)
    end

    logger.info("GET /locks/:account/*identifier ended successfully")
  end

  def update
    logger.info("PATCH /locks/:account/*identifier started")
    # authorize(:update, resource)

    delete_expired(params[:account])

    lock = get_lock_from_db(params[:account], params[:identifier])
    if lock
      current_timestamp = Time.now
      expires_at = current_timestamp + params[:ttl]
      lock.expires_at = expires_at
      lock.modified_at = current_timestamp
      lock.save
      render(json: lock.as_json, status: :ok)
    else
      raise Exceptions::RecordNotFound.new(params[:identifier], message: LOCK_NOT_FOUND)
    end

    logger.info("PATCH /locks/:account/*identifier ended successfully")
  end

  def delete
    logger.info("DELETE /locks/:account/*identifier started")
    # authorize(:delete, resource)

    delete_expired(params[:account])

    lock = get_lock_from_db(params[:account], params[:identifier])
    if lock
      lock.delete
      head :ok
    else
      raise Exceptions::RecordNotFound.new(params[:identifier], message: LOCK_NOT_FOUND)
    end

    logger.info("DELETE /locks/:account/*identifier ended successfully")
  end

  private

  def get_lock_from_db(account, lock_id)
    Lock.where(account: account, lock_id: lock_id).first
  end

  def delete_expired(account)
    Lock.where(Sequel.lit("account = ? AND expires_at <= NOW()", account)).delete
  end
end