# frozen_string_literal: true

class AccountsController < ApplicationController
  include AuthorizeResource
  include BodyParser

  def index
    authorize :read
    
    render json: Account.list
  end

  def create
    authorize :execute

    api_key = Account.create(account_name, current_user.role_id)

    render json: { id: account_name, api_key: api_key }, status: :created
  end

  def destroy
    authorize :update

    Account.new(account_name).delete

    head :no_content
  end

  protected

  def resource
    @resource ||= Account.find_or_create_accounts_resource
  end

  def account_name
    # Rails 5 requires parameters to be explicitly permitted before converting 
    # to Hash.  See: https://stackoverflow.com/a/46029524
    params.permit(:id)[:id]
  end
end
