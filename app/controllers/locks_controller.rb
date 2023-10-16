# frozen_string_literal: true

class LocksController < RestController
  include FindLock
  include AuthorizeResource
  include BodyParser

  before_action :current_user

  LOCK_NOT_FOUND = "Lock not found"
  ID_FIELD_ALLOWED_CHARACTERS = /\A[a-zA-Z0-9+\-_]+\z/

  def create
    logger.debug("POST /locks/:account started")
    authorize(:create)

    unless params[:ttl].is_a? Integer and params[:ttl] > 0
      raise ApplicationController::BadRequest, "invalid 'ttl' parameter. Must be a positive number"
    end

    unless params[:id].match?(ID_FIELD_ALLOWED_CHARACTERS)
      raise ApplicationController::BadRequest, "invalid 'id' parameter. Only the following characters are supported: A-Z, a-z, 0-9, +, -, and _"
    end

    delete_lock_if_expired(params[:account], params[:id])

    expires_at = Lock.db.get(Sequel.lit("CURRENT_TIMESTAMP + interval ?", "#{params[:ttl]} second"))
    lock = Lock.new(lock_id: params[:id], account: params[:account],
                    owner: params[:owner],
                    modified_at: Sequel::CURRENT_TIMESTAMP,
                    expires_at: expires_at)
    lock.save

    render(json: lock.as_json, status: :created)
    logger.debug("POST /locks/:account ended successfully")
  rescue Sequel::UniqueConstraintViolation => e
    logger.error("The lock [#{params[:id]}] already exists")
    logger.debug("POST /locks/:account ended successfully")
    raise Exceptions::RecordExists.new("lock", params[:id])
  end

  def get
    logger.debug("GET /locks/:account/*identifier started")
    authorize(:read)

    delete_lock_if_expired(params[:account], params[:identifier])
    lock = get_lock_from_db(params[:account], params[:identifier])
    if lock
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

    logger.debug("GET /locks/:account/*identifier ended successfully")
  end

  def update
    logger.debug("PATCH /locks/:account/*identifier started")
    authorize(:update)

    delete_lock_if_expired(params[:account], params[:identifier])
    lock = get_lock_from_db(params[:account], params[:identifier])
    if lock
      expires_at = Lock.db.get(Sequel.lit("CURRENT_TIMESTAMP + interval ?", "#{params[:ttl]} second"))
      Lock.where(account: account, lock_id: params[:identifier]).update(modified_at: Sequel::CURRENT_TIMESTAMP, expires_at: expires_at)
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
    logger.debug("PATCH /locks/:account/*identifier ended successfully")
  end

  def delete
    logger.debug("DELETE /locks/:account/*identifier started")
    authorize(:delete)

    delete_lock_if_expired(params[:account], params[:identifier])
    lock = get_lock_from_db(params[:account], params[:identifier])
    if lock
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
    logger.debug("DELETE /locks/:account/*identifier ended successfully")
  end

  private

  def get_lock_from_db(account, lock_id)
    Lock.where(account: account, lock_id: lock_id).first
  end

  def delete_lock_if_expired(account, lock_id)
    Lock.where(Sequel.lit("account = ? AND lock_id = ? AND expires_at <= NOW()", account, lock_id)).delete
  end
end