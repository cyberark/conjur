# frozen_string_literal: true

class LocksController < RestController
  include FindLock
  include AuthorizeResource
  include BodyParser

  before_action :current_user

  LOCK_NOT_FOUND = "Lock not found"

  def create
    logger.info("POST /locks/:account started")
    authorize(:create)

    delete_lock_if_expired(params[:account], params[:id])

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
    authorize(:read)

    lock = get_lock_from_db(params[:account], params[:identifier])
    if lock and delete_lock_if_expired(params[:account], params[:identifier]) == 0
      render(json: lock.as_json, status: :ok)
    else
      render(json: {
        error: {
          code: "not_found",
          message: "Lock not found",
          target: "lock",
          details: {
            code: "not_found",
            target: "id",
            message: params[:identifier]
          }
        }
      }, status: :not_found)
    end

    logger.info("GET /locks/:account/*identifier ended successfully")
  end

  def update
    logger.info("PATCH /locks/:account/*identifier started")
    authorize(:update)

    lock = get_lock_from_db(params[:account], params[:identifier])
    if lock and delete_lock_if_expired(params[:account], params[:identifier]) == 0
      current_timestamp = Time.now
      expires_at = current_timestamp + params[:ttl]
      Lock.where(account: account, lock_id: params[:identifier]).update(modified_at: current_timestamp, expires_at: expires_at)
      render(json: lock.as_json, status: :ok)
    else
      render(json: {
        error: {
          code: "not_found",
          message: "Lock not found",
          target: "lock",
          details: {
            code: "not_found",
            target: "id",
            message: params[:identifier]
          }
        }
      }, status: :not_found)
    end
    logger.info("PATCH /locks/:account/*identifier ended successfully")
  end

  def delete
    logger.info("DELETE /locks/:account/*identifier started")
    authorize(:delete)

    lock = get_lock_from_db(params[:account], params[:identifier])
    if lock and delete_lock_if_expired(params[:account], params[:identifier]) == 0
      lock.delete
      head :ok
    else
      render(json: {
        error: {
          code: "not_found",
          message: "Lock not found",
          target: "lock",
          details: {
            code: "not_found",
            target: "id",
            message: params[:identifier]
          }
        }
      }, status: :not_found)
    end
    logger.info("DELETE /locks/:account/*identifier ended successfully")
  end

  private

  def get_lock_from_db(account, lock_id)
    Lock.where(account: account, lock_id: lock_id).first
  end

  def delete_lock_if_expired(account, lock_id)
    Lock.where(Sequel.lit("account = ? AND lock_id = ? AND expires_at <= NOW()", account, lock_id)).delete
  end
end