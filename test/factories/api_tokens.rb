FactoryBot.define do
  factory :api_token do
    user { nil }
    name { "MyString" }
    token { "MyString" }
    last_used_at { "2025-10-15 01:58:49" }
    expires_at { "2025-10-15 01:58:49" }
    revoked_at { "2025-10-15 01:58:49" }
  end
end
