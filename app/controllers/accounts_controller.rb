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

    # Rails 5 changes the way to return no content:
    #
    # render nothing: true, status: :no_content
    head :no_content
  end

  protected

  def resource
    @resource ||= Account.find_or_create_accounts_resource
  end

  def account_name
    # allowed_params = [:account, :kind, :limit, :offset, :search]
    # options = params.permit(*allowed_params)
    #   .slice(*allowed_params).to_h.symbolize_keys
    # Rails 5 requires parameters to be explicitly permitted before converting 
    # to Hash.  See: https://stackoverflow.com/a/46029524

    params.permit(:id)[:id]
  end
end
