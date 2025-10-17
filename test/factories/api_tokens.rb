FactoryBot.define do
  factory :api_token do
    association :user

    name { "Test API Token" }
    expires_at { 30.days.from_now }
    revoked_at { nil }  # Not revoked by default
    last_used_at { nil }

    # Let the model generate the token via callbacks
  end
end
