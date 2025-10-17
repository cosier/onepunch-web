class AllowNullRedirectUriInOauthAuthorizationCodes < ActiveRecord::Migration[8.1]
  def change
    change_column_null :oauth_authorization_codes, :redirect_uri, true
  end
end
