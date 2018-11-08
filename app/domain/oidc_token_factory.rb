# frozen_string_literal: true

class OidcTokenFactory < TokenFactory
  
  def oidc_token(oidc_id_token_details)
    # TODO: add signing
    # TODO: encrypt the id_token
    ::Authentication::AuthnOidc::OidcConjurToken.new(
      id_token_encrypted: oidc_id_token_details.id_token,
      user_name: oidc_id_token_details.user_info.preferred_username,
      expiration_time: oidc_id_token_details.expiration_time
      )
  end

end
