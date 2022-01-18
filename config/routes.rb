Rails.application.routes.draw do
  use_doorkeeper do
    skip_controllers :authorizations, :applications, :authorized_applications, :token_info
  end

  get :'dns-query', controller: :dns_query, action: :show
  post :'dns-query', controller: :dns_query, action: :create
  match :'dns-query', controller: :dns_query, action: :not_implemented, via: :all
  # resource :'dns-query', controller: :dns_query, only: %i[show create]
end
