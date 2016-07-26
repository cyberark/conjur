class PublicKeysController < ApplicationController
  def show
    require 'slosilo'
    
    account, kind, id = [ params[:account], params[:kind], params[:identifier] ]

    values = Secret.latest_public_keys account, kind, id
          
    render text: ( values + [ ]).join("\n")
  end
end
