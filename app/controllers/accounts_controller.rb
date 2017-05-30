class AccountsController < ApplicationController
  include AuthorizeResource

  before_action :find_or_create_accounts_resource
  before_action :verify_account_available, only: [ :create ]
  before_action :find_account, only: [ :destroy ]

  def index
    authorize :read
    
    render json: Account.list
  end

  def create
    authorize :execute

    api_key = Account.create account_name

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

  def verify_account_available
    raise RecordExists, account_name if Slosilo["authn:#{account_name}"]
    true
  end

  def find_account
    @account = Slosilo["authn:#{account_name}"]
  end
end
