FactoryBot.define do
  factory :asana_credential do
    user { nil }
    access_token { "MyString" }
    refresh_token { "MyString" }
    expires_at { "2025-09-30 15:40:31" }
    workspace_gid { "MyString" }
    workspace_name { "MyString" }
  end
end
