# frozen_string_literal: true

class AccountsController < ApplicationController
  include AuthorizeResource

  before_action :find_or_create_accounts_resource

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

    render nothing: true, status: :no_content
  end

  protected

  def find_or_create_accounts_resource
    @resource = Account.find_or_create_accounts_resource
  end

  def account_name
    params[:id]
  end
end
