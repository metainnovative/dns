# frozen_string_literal: true

Doorkeeper.configure do
  orm :active_record

  resource_owner_from_credentials do |routes|
    user = User.find_for_database_authentication(email: params[:username])

    if user&.valid_for_authentication? { user.valid_password?(params[:password]) } && user&.active_for_authentication?
      request.env['warden'].set_user(user, scope: :user, store: false)
      user
    end
  end

  api_only
  authorization_code_expires_in 10.minutes
  access_token_expires_in 2.hours
  use_refresh_token
  skip_client_authentication_for_password_grant true
  allow_token_introspection false
  client_credentials :from_params
  access_token_methods :from_bearer_authorization
  grant_flows %i[password client_credentials]
end
