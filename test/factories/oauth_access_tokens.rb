FactoryBot.define do
  factory :oauth_access_token do
    token { "MyString" }
    refresh_token { "MyString" }
    oauth_application_id { 1 }
    user_id { 1 }
    scopes { "MyText" }
    expires_at { "2025-10-15 21:33:32" }
    revoked_at { "2025-10-15 21:33:32" }
    last_used_at { "2025-10-15 21:33:32" }
  end
end
