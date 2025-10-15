FactoryBot.define do
  factory :oauth_authorization_code do
    code { "MyString" }
    oauth_application_id { 1 }
    user_id { 1 }
    redirect_uri { "MyString" }
    scopes { "MyText" }
    code_challenge { "MyString" }
    code_challenge_method { "MyString" }
    expires_at { "2025-10-15 21:33:08" }
    revoked_at { "2025-10-15 21:33:08" }
  end
end
