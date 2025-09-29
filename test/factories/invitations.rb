FactoryBot.define do
  factory :invitation do
    organization { nil }
    invited_by { 1 }
    email { "MyString" }
    token { "MyString" }
    role { "MyString" }
    accepted_at { "2025-09-29 19:20:59" }
    expires_at { "2025-09-29 19:20:59" }
  end
end
